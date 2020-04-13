---
layout: post
title: Postgres Autovacuum, Vacuum and Analyze Explained
date: 2019-06-10 00:00:00 +0000
categories: docker
permalink: /@marcus/postgres-autovacuum-vacuum-and-analyze-explained/
---

This week I ran into something interesting on the current project that I'm working on. In the project, we have a PostgreSQL datamart where we store a ton of data generated from a machine learning model.

Data is added to the database every time a run finishes and each run contain hundreds of thousands of entries, on top of that we run around ~200 runs per day so that equals to at least 20M rows per day, ouch.

To make sure that the table does not swell too much we also have different cleanup jobs that delete data from runs that we don't want to keep. That also means that we delete millions of rows on a daily basis. To conclude, we both add and delete a ton of data from this table every single day.

Suddenly we noticed that `SELECT` queries to the database started getting slower and slower until they got painfully slow and it was my responsibility to look into the reason why. I quickly found out that a table of only 10M rows was 165 GB large with a 30 GB large index. What?!

That means that every row of data must contain 12 kB of data for it to make sense. Something fishy must be going on, it does not add up.

## Why Postgres Table Takes Huge Disk Space?
By inspecting the schema I was able to pretty quickly rule out that there was no way that a single row in the table would store 12 kB of data (or 12000 bytes).

Most of the column were integers which means that they only require 4 bytes of storage, there were a few `VARCHAR` fields but none of them stored more than 80 bytes of data (2+n where n is the character length).

If you have a similar issue you should pretty quickly be able to get a feeling if the storage size is reasonable or not. Take the full size of the table and divide it by the row count and then compare it with the schema to evaluate if it's a reasonable size or not.

The next step was to investigate if the table contained any dead tuples that were not cleaned up by vacuum. 

## Postgres uses Soft Delete when removing data
What do you think happens when you run a `DELETE` query in postgres? Do you think that the data is deleted? Wrong! All it does is to MARK the data for deletion.

PostgreSQL uses a "soft delete" way of deleting data. It might look like rows are deleted by the row count, but any deleted row is still there, just hidden from you when you are querying the database.

Even though its hidden, PostgreSQL still have to read through all of the rows marked as deleted whenever you are doing `SELECT`. 

Imagine that you have the following rows:

* ID: 1
* ID: 2, Deleted
* ID: 3
* ID: 4, Deleted

If you do a `SELECT COUNT(*) FROM t` it might only show `2` but in reality the postgres client is reading through all 4 of the rows and then throwing away the ones marked as deleted. Imagine if you have millions of "soft deleted" rows in a table, it's easy to understand how that would effect performance.

So the question is, why is Postgres deleting data in this manner? Actually it is one of the benefits of Postgres, it helps us handle many queries in parallel without locking the table.

Imagine if the database gets 2 requests, a `SELECT` and a `DELETE` that target the same data. If the data was completely removed then the `SELECT` query would probably error out inflight since the data would suddently go missing. 

Since Postgres uses a soft delete method, it means that the data is still there and each query can finish up. Any future `SELECT` queries would not return the data, but any that were transactioning as the delete occurs would.

The data is then supposed to be garbage collected by something called vacuum.

### Check Dead Tuples in PostgreSQL
I was able to confirm that dead rows (called Tuples in Postgres) were the reason for all the additional disk space by running the following query in Postgres:

```sql
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autoanalyze, last_autovacuum FROM pg_stat_all_tables ORDER BY last_autovacuum DESC NULLS LAST;
```

That will list all of your tables in your database ordered by when they were cleaned up by `autovacuum`. The `n_live_tup` is the remaining rows in your table while `n_dead_tup` is the number of rows that have been marked for deletion.

In my case I had millions of rows that had been marked for deletion but not removed, and because of this it was taking up gigabytes of storage on disk and it was slowing down all of my queries, since each query had to include all the deleted rows in the read (even if it then throws them away when it sees that is has been marked for deletion).

## What is Postgres Vacuum, Autovacuum and Analyze?
Vacuum is the garbage collector of postgres that go through the database and cleanup any data or rows that have been marked for deletion. Its job is to make sure that database tables do not get full of deleted rows that would impact the performance of the database.

> `VACUUM` reclaims storage occupied by dead tuples. In normal PostgreSQL operation, tuples that are deleted or obsoleted by an update are not physically removed from their table; they remain present until a VACUUM is done. Therefore it's necessary to do VACUUM periodically, especially on frequently-updated tables.

There are three parts of vacuum:

* The `VACUUM` command (with varients).
* The `VACUUM ANALYZE` command.
* The `autovacuum` garbage collector that runs automatically.

### Postgres Vacuum Command
There are a few different ways that you can use the `VACUUM` command:

* `VACUUM`
* `VACUUM FULL`
* `VACUUM FREEZE`

[There are a few additional ways](https://www.postgresql.org/docs/current/sql-vacuum.html), however these are the main use cases that you need to concern yourself with.

Executing `VACUUM` without anything else following it will simply cleanup all the dead tuples in your database and free up the disk space. This disk space will not be returned back to the OS but it will be usable again for Postgres.

Executing `VACUUM FULL` will take longer to execute than the standard `VACUUM` command because it stores a copy of the whole database on disk. The benefit of it is that you return all the storage back to the OS again.

Executing `VACUUM ANALYZE` has nothing to do with clean-up of dead tuples, instead what it does is store statistics about the data in the table so that the client can query the data more efficiently. 

Knowing about these manual commands is incredibly useful and valuable, however in my opinion you should not rely on these manual commands for cleaning up your database. Instead it should be done automatically with something called `autovacuum`.

### What is Postgres Autovacuum?
As you might guess by the name, `autovacuum` is the same thing as the normal `VACUUM` command described above, except that it is managed and executed automatically. 

Of course you could setup a cronjob that run `VACUUM` on a daily schedule, however that would not be very efficient and it would come with a lot of downsides such as:

* Your database now rely on some external service to work properly.
* The database might not need to do a `VACUUM` and you waste CPU resources for no reason.
* The database might be under heavy load with a ton of updates to the data and it will have to keep all of this until your prescheduled job occurs. 

The solution is to make sure that Postgres takes responsibility to cleanup its own data whenever its needed. This is what `autovacuum` is for.

Luckily for us, `autovacuum` is enabled by default on PostgreSQL. The default settings mean that it will cleanup a table whenever the table has more than 50 dead rows and those rows are more than 20% of the total row count of the table.

It is doing so by spawning an `autovacuum worker` process on the OS that executes the `VACUUM` command on a table at a time.

These settings are quite restrictive, imagine if you have a table that store 10 GB of data, a threshold of 20% would mean that it would collect 2 GB of dead rows before it would trigger the autovacuum. Ouch.

## Why is Autovacuum not working?
So if `autovacuum` is running by default, then why did I have gigabytes of undeleted data in my database that was just collecting dust and grinding my database to a halt?

You could see by the query listed further up in this article that listed the tables by latest autovacuum, that autovaccum actually *was* running, it was just that it was not running often and fast enough. It was never able to catch up with the millions of row changes per day so the dead tuples were just stacking on top of each other more and more for each day passing by.

This all happened because the default settings of Postgres is there to support the smallest of databases on the smallest of devices. You can run a postgres database on a raspberry pi or other tiny devices with very few resources.

Since the threshold was set to 20% by default, and the worker cost limit was set to the default amount, it meant that the `autovacuum` workers were spawned rarely and each time they were spawned they did a tiny amount of work before they were paused again. That's why autovacuum wasn't working for me in my case.

## How to configure Autovacuum to run more often?
This post has become quite long already and I will cover the Autovacuum configurations in a separate post, but generally to increase the amount of cleanup that your postgres database will do can be controlled by 2 parameters:

* `autovacuum_vacuum_cost_limit`, default `200`. This setting determines how much work the worker should do before it goes back to sleep.
* `autovacuum_vacuum_scale_factor`, default `0.2`. This setting determines how much of the table must be dead until it starts cleaning it up. The default value `0.2` means 20% of total row count must be dead tuples.

By increasing the `_cost_limit` to something like `2000` and also decreasing the `_scale_factor` to something like `0.05` (5%) it means that we can make the autovacuum run more often, and each time it runs it will cleanup more before it pauses.

Tweaking these parameters was enough for me to fix the issues I was experiencing with my database. By making sure that `autovacuum` had enough time to run every day, I was able to reduce the row count and disk space of the database by 95% -- a huge amount.