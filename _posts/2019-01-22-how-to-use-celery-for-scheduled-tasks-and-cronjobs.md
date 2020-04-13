---
layout: post
title: How to use Celery for Scheduled Tasks and Cronjobs
date: 2019-01-22 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-use-celery-for-scheduled-tasks-and-cronjobs/
---

A very common, reoccurring thing that developers want to create is a feature that occurs over and over again on a certain schedule. This could be things like emailing out notifications at certain intervals, clearing some data from the database, deleting log files on the system or maybe just prepare data by conducting some heavy task in the middle of the night so it can be consumed in the morning by the users.

Whatever it is, the common thing between these things is that it is tasks that are being executed automatically on a a fixed schedule instead of by a user pressing a button or loading a page.

The traditional way to solve these things is to setup a cronjob in the `crontab` of your Linux server. You can for example create an URL in your application that the cronjob sends a HTTP request to every night that triggers the execution of the script, or maybe you just have a script file located on the server that the cronjob executes.

When it comes to system actions, like clearing log files, I have no issues with this approach. But when it comes to application actions, like sending out email notifications, I've always felt a bit uncomfortable with setting them up as cronjobs. Why?

## Bundle Scheduled Tasks with Application
One of the main points of the [12 Factor Methodology](https://coderbook.com/@marcus/how-to-use-the-12-factor-app-methodology-in-practice/) is that your application is ready to be executed as it is. You want to bundle it to an image or an executable and then when you setup a new server instance its ready to go from the start.

I agree with this idea, and because of it I prefer that my application does not rely on system configuration, and that anything required for it to work properly is bundled together with it. In the case of scheduled tasks, I want them to be tightly coupled with my application so that I can feel confident that they will be setup correctly and executed as expected on any server that I deploy my application on.

Cronjobs are defined within the `crontab` on a system level. How do we achieve a similar functionality on the application level? The answer is named by a green vegetable called Celery.

## How to Schedule Tasks with Celery Heartbeat
[Celery](http://www.celeryproject.org/) is a popular tool for handling asynchronous tasks. What it does is that it allow us to send messages from our application to a message queue like RabbitMQ, and then the celery worker will pickup these messages and execute them within its worker process, which is a process that will be executed separately from your main application.

This means that we could do execute long running tasks in the background while our web application keep serving the web requests to our users. 

In the use case of this particular article, we are primarily interested in how we can execute tasks on a fixed schedule, so for the purpose of sticking to our point we will ignore some of the other features of Celery for now.

### Install and Configure Celery
Celery is easy to install, just install the Python package using pip:

	::bash
	# Note a more recent version might have been
	# released at the time you're reading this article.
	pip install celery>=4.2.1
	
The next step is to create a `/tasks/` directory within our application where we will store our Celery related configurations and files. Start by initiating the following files:

	::bash
	./
		/tasks
			__init__.py
			celery.py
			config.py

The first file we will populate is the `celery.py` file.

	::python
	from celery import Celery
	
	
	app = Celery("tasks")
	app.config_from_object("tasks.config", namespace="CELERY")

Let's summarize what we're doing in this file:

- We create a Celery application that we name "tasks" that we store in the `app` variable.
- We load in a Celery config from our python path `tasks.config`, which means that our `config.py` file within the `/tasks/` directory will hold our configuration values. The `namespace="CELERY"` means that we are expecting all of the configuration values to be prefixed with `CELERY_`. This is very useful if you have a larger project with a single config file that you define both your Celery and the rest of your applications configuration within.

Next step will be to populate our `config.py` file:

	::python
	import os


	BROKER_USER = os.environ.get("BROKER_USER")
	BROKER_PASSWORD = os.environ.get("BROKER_PASSWORD")
	BROKER_HOST = os.environ.get("BROKER_HOST")
	BROKER_PORT = os.environ.get("BROKER_PORT")
	BROKER_VHOST = os.environ.get("BROKER_VHOST")


	CELERY_BROKER_URL=f"amqp://{BROKER_USER}:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/{BROKER_VHOST}"

All we define in our configuration is the `CELERY_BROKER_URL` which holds the URL to our RabbitMQ Broker that is using the `amqp://` protocol for its communication. This will be the broker that store all of our messages. Within the [Celery Documentation](http://docs.celeryproject.org/en/latest/getting-started/brokers/index.html) you can find examples of other types of brokers such as AWS SQS, Redis and more. I prefer using RabbitMQ.

### Create our Scheduled Task
Tasks are just regular Python functions that we decorate with a `@task` decorator. The decorator will register the function with Celery so that it knows how to send incoming messages to it.

Let's create a sample Task that will email notifications to all of our users.

	::python
	from tasks.celery import app
	from myproject.models import User
	
	
	@app.task(name="myproject.send_emails")
	def send_email_task():
		"""Task that send email to all users"""
		users = User.objects.all()
		send_user_emails(users=users)

The important part here is that you study how we decorate a method to become a task of a Celery application. Notice that we import the `app` variable from our `/tasks/celery.py` file that we created before, and then use it to decorate our function to register it as a task.

The `name` argument passed into the decorator is not mandatory, but it makes it explicit and easy to understand for any developer how to call the task. If you don't define the name argument, the signature of the task will be the python path to it, relative from the Celery worker.

Note that this task code could live within your `celery.py` file, but you could also place it elsewhere within your code repository. If you place it outside of your `celery.py` file you will have to tell Celery how it can find your task. 

You can either do this by using the `app.autodiscover_tasks()` method, or by adding a `include=[]` kwargs to your `Celery()` initiation that will include all the python paths that it should be looking for tasks in.

### Create our Celery Heartbeat Schedule
Let's go back to our `celery.py` file to define the schedule of when we want our `myproject.send_emails` task to be executed.


	::python
	from celery import Celery
	from celery.schedules import crontab
	
	
	app = Celery("tasks")
	app.config_from_object("tasks.config", namespace="CELERY")
	
	app.conf.beat_schedule = {
		"trigger-email-notifications": {
			"task": "myproject.send_emails",
			"schedule": crontab(minute="0", hour="0", day="*")
		}
	}

- We create a new schedule that we name `trigger-email-notifications` that execute our task `myproject.send_emails`.
- We import Celery's `crontab` method that allow us to define a schedule in a crontab format. In our case we define it so that the task will be triggered at 00:00 every day.

For those we are new to Crontab, the way Crontab allow us to schedule jobs is by 5 different parameters and the format will be:

	::bash
	Minute  Hour  Day  Month  Day
	*       *     *    *      *

The first "Day" stands for Day of month. So 1 would be the first of the month. The second "Day" stands for Day of Week, so 1 would mean "Monday".

Each value can either be an asterisk which means "every", or a number to define a specific value. So in our case `0 0 * * *` stands for Minute 0 on Hour 0, Every Day or in plain English "00:00 Every Day".

### Run our Celery Worker to Execute Tasks
As mentioned in the beginning of this article, a Celery Worker is a process that will run in the background separate from your main application. Because of this we have to spawn the process using the `celery worker` command.

To run the worker that will execute heartbeats for our example above we need to run the following command:

	::bash
	celery -A tasks worker -B -Q celery -l DEBUG

Let's summarize what all of this does:

- `-A` stands for "App" and it asks us to define the name of the Celery Application that we created within our `celery.py` file. Remember we named it "tasks"? Because of this we tell the Celery worker that it should run the "tasks app" by specifying `-A tasks`.
- `worker` is just the command that tells `celery` to spawn a worker.
- `-B` stands for that the worker should execute Beats/Heartbeats which is Celery's term for scheduled tasks, which is what we have defined for our application. Notice that if you run multiple workers, only one of them should have the `-B` option.
- `-Q` stands for the queue we want to use to listen for incoming messages. The default value is `celery` so we don't necessarily need to define it explicitly like this, but you can also replace this to other queues -- it's always good to be explicit for when other developers come along.
- `-l` stands for the log level that we want to activate for our worker. You can change this to `INFO`, `WARNING`, `ERROR` just like any other logger.

That's it! Your worker should now be running and execute your scheduled tasks once a day.

## How to Test Celery Scheduled Tasks
When you define a celery task to be conducted in the background once a day, it might be difficult to keep track on if things are actually being executed or not. I therefor suggest you to do 2 things:

- Test your task on a faster schedule like `* * * * *` which means that it will execute every minute.
- Add logging to your task.

The first one is a great way to at least make sure that your task is being called before you deploy it all to production. By making sure that it executes every minute it **should** then execute things when you change it to your real schedule.

The second point is often overlooked and its such a great and simple way to follow up on what work that your code is executing. Adding logging can be done with just a few lines of code in a very simple manner.

	::python
	import logging
	from tasks.celery import app
	from myproject.models import User


	logger = logging.getLogger(__name__)

	
	@app.task(name="myproject.send_emails")
	def send_email_task():
		"""Task that send email to all users"""
		users = User.objects.all()
		send_user_emails(users=users)
		logger.debug(f"Emails were send out to {len(users)} users")

Celery will automatically pickup these log messages and output them in the `stdout` of the Celery Worker Process. By doing this simple change you can now follow up on the execution of your tasks and feel confident that they are being executed as expected.
