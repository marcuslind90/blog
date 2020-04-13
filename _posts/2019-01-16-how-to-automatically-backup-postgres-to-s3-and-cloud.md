---
layout: post
title: How to Automatically Backup Postgres to S3 and Cloud
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-automatically-backup-postgres-to-s3-and-cloud/
---

Many modern cloud providers such as Amazon Web Services or Microsoft Azure offer managed database instances that makes it much easier to properly provision and run a database. They can help you with scaling, high availability fallbacks and backups.

Unfortunately as a DevOps engineer, life is not always this easy. You might work with a  cloud provider such as DigitalOcean that doesn't offer these type of managed services, or perhaps you or the company you work for decided to buy a server rack and run your own physical servers where you need to manage all of it by yourself.

In my case I was recently setting up an application infrastructure on DigitalOcean and one of the requirements was that the PostgreSQL database had to be backed up daily, but DigitalOcean only offered weekly backups of their droplets with no ability to customize this schedule.

Because of this, I had to plan how we would automatically run backups on a daily schedule that would store the database state on DigitalOcean's S3 cloud storage called "DigitalOcean Spaces". How did I achieve this?

## Export PostgreSQL Database using pg_dump and gzip
The first step was to write a script that would export the database without locking tables or in any way impact the user experience of the application. Postgres offers a very handy utility for this called `pg_dump` that writes your database to stdout which means that you can also pipe this output using other Linux commands or operations.

For example, you could write `pg_dump dbname > dbname.sql` to export the `dbname` database to a file called `dbname.sql`, or if you have a large database you could also pipe the output with `gzip` and store it as a zipped file by using `pg_dump dbname | gzip > dbname.sql.gz`.

Handy, right?

In my case I was running PostgreSQL in a Docker container so my `~/backup.sh` script ended up looking like this:

	::bash
	#!/bin/bash
	docker exec $(docker ps -q) pg_dump dbname -U dbuser | gzip > /backup/backup.sql.gz
	
This would then run the `pg_dump` command within my docker container and store it within the containers `/backup` folder. Since I mounted this volume to the host machine, it means that this new `backup.sql.gz` was also available on the host machine where the script was running.

## Use rclone to copy file to S3 and Cloud
I found a handy little tool called [rclone](https://rclone.org/) which calls itself *"rsync for cloud storage"*. At the time of writing this article it allows you to copy files to a large amount of cloud providers including Amazon Web Services S3, DigitalOcean Spaces, Microsoft Azure Blob Storage, Dropbox and more.

I installed it on my DigitalOcean Ubuntu droplet with the following command:

	::bash
	curl https://rclone.org/install.sh | sudo bash
	
After installing I had to create a `~/rclone.conf` file that I populated with the following settings that would allow me to authenticate with DigitalOcean Spaces and upload my backup file to it using the S3 protocol. As you can see the `${SPACES_ACCESS_KEY}` and `${SPACES_SECRET_KEY}` is environment variables that hold my secret keys required to authenticate with my storage.

	::bash
	[spaces]
	type = s3
	env_auth = false
	access_key_id = ${SPACES_ACCESS_KEY}
	secret_access_key = ${SPACES_SECRET_KEY}
	endpoint = sfo2.digitaloceanspaces.com
	acl = private
	
At this point I just had to add `rclone` to my `~/backup.sh` file described in the previous section and after that my final script was done and was looking like this:

	::bash
	#!/bin/bash
	mkdir -p /backup
	docker exec $(docker ps -q) pg_dump dbname -U dbuser | gzip > /backup/backup.sql.gz
	rclone --config ~/rclone.conf mkdir "spaces:myspaces/backups/$(date +%d)"
	rclone --config ~/rclone.conf copy /backup "spaces:myspaces/backups/$(date +%d)"

So to quickly summarize what this script does line by line:

1. Create a new folder on the host machine called `/backup`. My docker configuration mounts the containers `/backup` folder to my host's `/backup` folder. 
2. Run my `pg_dump` command inside the container that exports my database and pipes it through the `gzip` utility tool which allows me to save it as a compressed `.gz` file.
3. Use `rclone` to create a new directory within my DigitalOcean Spaces S3 storage. I use `$(date +%d)` to create a folder named by the day of the month. E.g. 01, 02, 03, 04 etc. This means that I will keep backups for 1 month rolling, so after a month have passed it will start overwriting the backups from the previous month.
4. I finaly use `rclone` to copy my `/backup` folder (which now contains my `backup.sql.gz` file) to my remote S3 storage.

Note that all of this can very easily be done with AWS S3 as well since it's using the same protocol. If you use other types of storage you can find more details within the [rclone documentation](https://rclone.org/).

## Schedule backups to run daily
At this point we already have our backup script ready and we should be able to try it out by simply running it with `bash ~/backup.sh`. This should then export the database and copy it to the cloud. 

Obviously we do not want to do this manually every day, our goal is to automate it so that we can rely on always having database backups without human action. How do we achieve this? With a simple cronjob.

A cronjob is a scheduled command that reoccurs at a defined schedule. This can be any type of command such as downloading a file, doing a HTTP request, running a bash script and more. Sounds like a perfect fit for our use case, right?

I created a `/etc/cron.d/backup-cron` file that contained the following content:

	::bash
	0 0 * * * sh ~/backup.sh

I then add this to my droplet's crontab by executing `crontab /etc/cron.d/backup-cron`. You can check if it has been added to your crontab by typing `crontab -e` to see existing cronjobs on your server instance.

The content of my `backup-cron` file is pretty straight forward. The first 5 characters is the schedule, and anything behind it is the command. So in our case `0 0 * * *` means that our command will run at minute 0 at hour 0, every day, every week, every month. Translated to normal English that means that it is scheduled to run `00:00` daily.

Since then I've had this script running on a daily schedule for weeks and its still reliably backing up the database of the application and storing it in the cloud. Works like a charm.
