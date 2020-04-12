---
layout: post
title: How to replicate PostgreSQL Database as Master/Slave
date: 2019-01-17 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-replicate-postgresql-database-as-masterslave
---

Most websites out there perform fine by simply having a web server instance and a database server instance, but if you are one of the lucky few who manage to get real traction to your business and start attracting serious number of visitors, you'll quite quickly run into your first bottleneck, your database.

Of course every application is different and might have different needs and because of this, there might be other things within your specific application that you need to work on. But in my own experience, it's almost always the database that starts to slow down first. 

So what do you do when you're starting having database performance issues? You might first attempt to optimize your database queries, add the correct indexes and maybe even reduce joins by changing table structure. But soon enough you'll need to change the actual infrastructure. 

You have 2 options for this. Horizontal scaling or Vertical scaling.

Vertical scaling is when you keep upgrading your existing server and you scale it by making it more and more powerful. This could work quite well for some applications since it's such an easy thing to do. You just "upgrade your server" and pay more money for it. Voila! 

The problem with this though is that there's a limit to how much you can scale a single database server. We don't have infinite amount of processing power or memory for a single machine and if you keep growing and keep receiving more and more users, vertical scaling will at some point not work anymore. 

A second downside with vertical scaling is that you have a single-point-of-failure within your infrastructure. If your single database instance goes down, so does your whole website. Ouch. 

That's where horizontal scaling comes in, and that's what we'll talk about today.

## Why Horizontal Database Scaling
Horizontal scaling means that instead of only making a single instance larger and more powerful, we scale our system by adding more instances that work side by side with each other. 

You could have 2 databases, 10, 100 or 1000'nds. Unlike vertical scaling, with horizontal scaling you can just keep scaling and scaling and scaling. In theory, there is no limit of how much you can keep growing.

Now with that said, there are different types of horizontal scaling and depending on your read/write ratio different types of scaling might have a different impact on your business.

The most common type is where you have a single write instance (master), and an X number of replicas (slaves) that only accept read-queries. This means that every single `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER` query goes to a single database instance, but every `SELECT` query will be split among all of your databases.

Sounds like a lot of work for the master, and for some applications it is. But generally an application will need to accept far more read queries than write queries. Let's take this website as an example. Every time an article is created, a comment is posted or a user signs up, we need to write this data to the database. However for every single page view we need to read the user's data, the article's content and so much more, just to render the page you're looking at.

In the case of Coderbook.com, our amount of read queries are far greater than our writes and the type of horizontal scaling described above would work perfect for us.

## How to setup a Master server with PostgreSQL
[PostgreSQL Documentation on High Availability](https://www.postgresql.org/docs/9.6/high-availability.html) is a great resource to use for learning more about how you can scale your database and make sure you have a fallback that will take over the job if your master database crashes. However it quickly gets overwhelming with that kind of format. So I'll take you through how I setup replication with a Master/Slave PostgreSQL Database setup with an example instead.

The steps involved with setting up the replication is the following:

- Add configuration values to `postgresql.conf` that allow replication.
- Add a `recovery.conf` file to the slaves that informs the slave that it actually is a slave, and tells it how to communicate with the master.
- Add a `pg_hba.conf` to the master that tells it which instances are allowed to communicate and authenticate with it.
- Read in the master data to the replica to keep them at the same state.

### Add Replication Configuration to postgresql.conf
The first step when it comes to setting up replication is to change the configuration values of your main `postgresql.conf` file. The great thing is that you can share this configuration file across all of your instances, no matter if they are a Master or a Slave instance.

PostgreSQL knows which values to ignore based on if it's running as a Master or Slave. So the configuration values that only relate to Master instances will be ignored if the server is being run as a Slave and the other way around.

	::bash
	wal_level = hot_standby
	max_wal_senders = $PG_MAX_WAL_SENDERS
	wal_keep_segments = $PG_WAL_KEEP_SEGMENTS
	hot_standby = on
	
As you can see, most settings relate to something that PostgreSQL call "wal". This stands for "Write Ahead Log" and it is what we use to replicate data between instances.

- `wal_level` controls how much data is stored within the WAL. The default value is `minimal` which isn't enough for us to replicate data.
- `max_wal_senders` controls the maximum numbers of concurrent requests that can be send from slaves or replicates to sync the data. The default is set to 0 which means that replication is off by default. This should be set to the amount of replicas we have. If we have 2 replicas then the value would be `2`. In the example we set it using an environment variable.
- `wal_keep_segments` specifies how long history the WAL keeps. What this means is that if the replica gets out of sync with more data than the master keeps within the WAL, the replication connection will be disconnected since data will be missing. WE define this using an environment variable, but it should be set to an integer and the value is multiplied by 16MB of data segments. So `8` would mean that the WAL keep 128MB of data.
- `hot_standby` specifies whether or not we can connect and run queries during recovery. Default value is `off` and we need to set it to `on` for our replication to work.

### Configure Host Based Authentication with pg_hba.conf
To allow our slave databases to connect to our master, we have to allow its access within the `pg_hba.conf` file of the master database.

HBA stands for host-based authentication and the `pg_hba.conf` file allow us to inform the database which other sources that are allowed to authenticate with it. This can be important for security reasons, since you might want to limit connections to only be allowed from your own known sources, to avoid unknown sources to try to read your data.

In my case, I prefer to limit access to the database instances with Firewalls on a higher level, and because of this I allow authentication from any source within my `pg_hba.conf` file. Simply put, I don't need to worry about unknown connections since by database is not exposed to the public.

	::bash
	host replication all 0.0.0.0/0 md5
	host all all 0.0.0.0/0 md5

This simply means that any IP is allowed to connect. The CIDR block syntax 0.0.0.0/0 means that it will match any IP address. If you have a public database, it is important that you limit the connections to only come from your other servers.

## How to setup a Slave or Replica PostgreSQL Server
All of the things that we mentioned on the previous section can be applied to all database servers within your cluster. So how does PostgreSQL know which ones are Replicas and which one is the Master? It knows so by looking for the existence of the file `recovery.conf`. If this file exists, PostgreSQL treats the server as a Slave/Replica.

### Setting Configuration of recovery.conf
The `recovery.conf` file describes to PostgreSQL how it should replicate data from the master to itself. For our case it will look like this:

	::bash
	standby_mode = on
	primary_conninfo = 'host=${REPLICATE_FROM} port=5432 user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
	trigger_file = '/tmp/promote_to_master'

- `standby_mode` controls if the server is "on standby" or not. This simply means if the database should continue trying to recover data from the master, even after it's been up to sync. It should always keep checking if more data is available.
- `primary_conninfo` is a string that describes how the connection to our master database looks like. In my case I use environment variables for the master hostname, master username and master password. You should replace these values with your own.
- `trigger_file` is a very efficient and simple way that allow us to promote our slave/replica to become its own Master. If this file is created/touched PostgreSQL will automatically upgrade itself to become a Master instance, stop replication and start allowing write requests.

### Get Initial Data from Master
Before you start the replica database you should read in the master database to make sure both of them are synced. If you do not do this you will see errors when it tries to replicate from master to slave.

	::bash
	sudo -u postgres pg_basebackup -h ${REPLICATE_FROM} -D ${PGDATA} -U ${POSTGRES_USER} -vP -w

By using the `pg_basebackup` utility we can get an initial state from the master to our replica. The environment variables needed are the following:

- `$REPLICATE_FROM` is the hostname of the master database that we want to replicate data from.
- `$PGDATA` is the directory path of where we store our PostgreSQL Data files. An example of this could be `/var/lib/postgresql/9.6/main`. Note that it differs depending on version.
- `$POSTGRES_USER` is the username on our master database that we want to authenticate with.

At this point you should be able to start your server and replication should be up and running. You can try this by making a simple `INSERT` or `CREATE` statement on your master database and do a `\dt` or `SELECT` statement on your replica to see if the data is synced.

## How to promote Slave to Master
On the previous step you could see the `trigger_file` configuration value. This is a file path that our replica checks for and if its there, it will automatically upgrade the replica to Master. 

So why would you want this? Well imagine if you had a script that monitored your master database, if the connection to it was lost you could simply promote one of the replicas to take over and read/write data to the replica instead. This will make sure that your database has "high availability" and removes any "single point of failure".

All of this would be done by just having a script do `touch /tmp/promote_to_master`.

By using a Floating IP/Virtual IP/Elastic IP that point to your write database, you could then also simply point the IP to your new master so that your application automatically always writes to the correct master without having to add any type of logic to it.

## How to do replicate with PostgreSQL Docker Image
[Daniel Dent has a great repository](https://github.com/DanielDent/docker-postgres-replication) with an example of how you can setup replication with Docker. I highly recommend you to look through his bash scripts that is executed with the Docker image is created, to have a good understanding with great examples of how its all being done.
