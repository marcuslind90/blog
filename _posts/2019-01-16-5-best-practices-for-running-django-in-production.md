---
layout: post
title: 5 Best Practices for Running Django in Production
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/5-best-practices-for-running-django-in-production
---

So you've created your Django application and you're finally ready to deploy your code to your public server where you'll be expect to get a ton of visitor coming to your website to enjoy your content. What can you do to prepare for this and make sure that your website perform as good as possible in a production environment?

I've personally been in this situation many times over for each and every one of the many projects that I've created using Django that has gone into production. During all my deployments there have been many lessons learned and I've finally created a check list of what both me and you should do when we prepare our Django website for production.

## Store configuration and credentials as environment variables
When you create your project using the `django-admin` tool provided, it automatically generates the `settings.py` file that contain your Django configuration. This file will contain things such as `DEBUG`, `DATABASES`, `SECRET_KEY`.

There are plenty of things in your settings file that you want to change between running the application on your localhost compared to the production environment. For example, you might want to replace the hostname to the database instance, change `DEBUG` to avoid displaying traceback's to visitors and use different credentials for external services.

Some of these things you could keep in a separate settings file, perhaps you have a `dev.py` settings file and a `prod.py` settings file. That might work well for some things, but you want to keep the differences between these files to the minimum to avoid any confusion and complexity of your application. 

The solution to many of these things is to store your configuration values as environment variables. You might have a `DB_HOSTNAME` environment variable that you set to `localhost` on your development environment and `db.domain.tld:5432` on your production environment.

One big benefit of this is that you can very easily replace config values that differ between environments, but another one is that you can change configuration without having to re-build and re-deploy your application. 

Imagine that you want to activate some kind of logging, or temporary enable `DEBUG` mode, or perhaps change the ip-address of your database server. All of this could be done instantly by changing the server's environment variable instead of having to change your code and redeploy your entire application.

A second, very significant advantage of doing this is that you will be able to hide your secrets and your credentials from your repository. If you do this correctly you should be able to feel completely comfortable with your data and the security of your application even if some hostile party got access to all of your code and repository. Remember -- most attacks happen because of employees, so even your own developers might be a security risk if they can see the database password or the Django `SECRET_KEY` setting in clear text.

So instead of writing out these things in clear text you use the `os` library to read in environment variables to your code. 

	::python
	import os
	
	
	DEBUG = os.environ.get('DEBUG', False)
	SECRET_KEY = os.environ.get('SECRET_KEY')
	DATABASES = {
		'default': {
			'ENGINE': 'django.db.backends.postgresql',
			'NAME': os.environ.get('RDS_DB_NAME'),
			'USER': os.environ.get('RDS_USERNAME'),
			'PASSWORD': os.environ.get('RDS_PASSWORD'),
			'HOST': os.environ.get('RDS_HOST'),
			'PORT': os.environ.get('RDS_PORT'),
		}
	}
	
So the question is, how can you easily define all of these environment variables? Especially when you're running your application on your local machine, you might require different environment variables for each project and you don't want to set it all on your operating system level.

### Reading in Environment Variables with Docker
If you're using Docker with Docker-Compose you can simply define an `env_file` setting that point to a `.env` file that you add to your `.gitignore` file to make sure that it never gets checked into your repository. This file will simply contain the environment variables for your environment in the following format:

	::bash
	DB_HOST=localhost
	DB_PORT=5432
	DB_USER=postgres
	DB_PASSWORD=helloworld
	
Docker will then read in this file and define the variables within the container every time you run it. Great isn't it?

### Reading in Environment Variables with python-dotenv
If you're not using Docker and simply want to read in an `.env` file with pure python you can use the [python-dotenv](https://github.com/theskumar/python-dotenv) package which allow you to load in the environment variables defined in your `.env` file to your application. 

This works in a very similar way to the Docker option described above. They also have documentation that describe multiple use cases, including using it with Django.

## Store media and static files in the cloud
By default both media and static files of Django is stored locally together with your application. This might work great when you're developing but as soon as you go into production you will soon run into trouble. 

Imagine that you created a production server and deployed your application that allow users to upload their profile images as media files. How would you go about changing server? Perhaps you found a cheaper alternative or maybe you want to move to a quicker host.

At this point in time you might have tens of thousands of profile images uploaded to your application and instead of just pulling your code to a new server and pointing your DNS entry to it, you will now also have to migrate all of the media content from your server. Ouch.

This is especially true for Media files since they are not part of your application and instead is uploaded by the users interacting with your application. You cannot recreate all media files on a new server, you have to manually migrate them.

The same problem would also occur if you want to start scaling your application. Imagine that you have so much traffic that you need to setup a second server and load balancer traffic between them. If each server store their own media files, it would mean that depending on if the visitor get sent to Server A or Server B, they would, or wouldn't have access to the files they try to access.

The solution to all of this is to store all of your media and static files on a remote storage that is decoupled from your server instances. This is one of those things that I feel is a must for any production website, it will cause a lot of headaches in the future if you don't do this.

### How to store Django files in the cloud
Django have a great package called [Django Storages](https://github.com/jschneier/django-storages) that support storage backends for many different storage solutions such as Amazon S3, DigitalOcean Spaces, Azure Blob Storage and more.

You just install the package, set the required settings and voila, now all your media files will be uploaded to the cloud, and all your static files will be copied to the cloud when you use the `./manage.py collectstatic` command.

## Turn off debug mode
In Django's `settings.py` file you will find the `DEBUG` setting that is a boolean value set to `True` or `False`. This value should always be set to `False` in production for multiple reasons.

First of all, it does the obvious thing which is that it turns off the debug mode. This means that when an error occurs on your website you will not receive a traceback and instead be shown an error page that either just display the HTTP status code of the error or you could customize this template.

This is very important because it helps you hide secret information. The Traceback could contain secret credentials or give insight to your code that you will want to keep away from the public eye. 

The second reason why it is important is because of performance reasons. The Django Template Loader is quite fast, but overheard can quickly add up and for that reason we want to make sure that we use the [Template Cache Loader](https://docs.djangoproject.com/en/2.1/ref/templates/api/#django.template.loaders.cached.Loader). Before Django 1.11 you had to manually activate this but since then it automatically gets set when we turn off the debug mode by setting `DEBUG=False`. 

A final thing to notice is that when you use the `DEBUG=True` mode during development, Django will store every SQL query that you executed in memory to make debugging easier. This will eat up your memory quickly on a production server and it is also something that is easily solved by making sure that the `DEBUG` setting always is set to `False`.

## Activate logging in Django Settings
Did you ever have a product owner, a client or a visitor call you up and inform you that they encountered an error on your website? 

As a programmer you obviously want to have additional information so that you can solve it, maybe you ask for a detailed error message, which page it happened on or even a screen shot. What answer will you most often get? "I don't remember". In some cases you might not even be sure if there is any error at all or if it's just the user who is doing something wrong.

The simple but efficient answer to this problem is logging! Unfortunately more often than not this core feature of any programming language is ignored and put to the side as something that's not of any particular important priority. Developers with that mind set will come to regret that attitude as soon as they encounter the scenario described above (which will happen!), when they are helpless in managing to figure out what might have gone wrong.

Django will make it easy for you to [configure logging](https://docs.djangoproject.com/en/2.1/topics/logging/#configuring-logging) in your `settings.py` file. Out of the box it comes with handlers for writing to files, stdout, email and more. 

A suggested configuration is to log all messages to a file, and then alert the administrators of the website by email if there is any serious errors happening on the website. You could achieve that type of configuration with the following settings:


	::python
	ADMINS = [('John', 'john@example.com'), ('Mary', 'mary@example.com')]
	LOGGING = {
		'version': 1,
		'disable_existing_loggers': False,
		'formatters': {
			'simple': {
				'format': '{levelname} {message}',
				'style': '{',
			},
		},
		'handlers': {
			'file': {
				'level': 'INFO',
				'class': 'logging.FileHandler',
				'filename': '/path/to/django/debug.log',
			},
			'mail_admins': {
				'level': 'ERROR',
				'class': 'django.utils.log.AdminEmailHandler',
			}
		},
		'loggers': {
			'django': {
				'handlers': ['file', 'mail_admins'],
				'propagate': True,
			},
		}
	}

With that type of configuration you will be alerted immediately when an `ERROR` level log message occurred, and for any other issue it will allow you to simply go back to the log file and investigate further.

Remember that the `AdminEmailHandler` will attempt to use the `send_mail()` function provided by Django to send the email using your defined `EMAIL_BACKEND`. This means that you have to define and configure an `EMAIL_BACKEND` before you can use this feature for delivering log messages.

## Serve your application using Nginx and Gunicorn
Up until now you've server your application in development using the `python manage.py runserver` command. This is a great little tool while you're hacking away and building new features, but its not enough for delivering your website on scale in production.

My preferred setup is to use [Nginx](https://nginx.org/) together with [Gunicorn](https://gunicorn.org/). It's very simple to setup and you use Nginx as a "reverse proxy" to pass through the traffic to Gunicorn, which will then serve the website through the WSGI interface provided by Django in the `wsgi.py` file. 

The configuration of Nginx and how to run it with Gunicorn can be quite a large discussion that I will cover in a separate post.
