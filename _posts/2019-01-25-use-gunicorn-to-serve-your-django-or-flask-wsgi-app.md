---
layout: post
title: Use Gunicorn To Serve Your Django or Flask WSGI App
date: 2019-01-25 00:00:00 +0000
categories: docker
permalink: /@marcus/use-gunicorn-to-serve-your-django-or-flask-wsgi-app
---

Using Gunicorn to serve your python WSGI web application is the next step to take after you've finally spent those days creating the first prototype of your new application and you're ready to serve it in production. 

But what is WSGI? What is Gunicorn used for and why do you need to combine Gunicorn with something like Nginx? Isn't Gunicorn a web server by itself?

In this article, I'll take you through how we can use Gunicorn to serve our web applications no matter if they are built with web frameworks such as Django and Flask, or if you hacked together something on your own. Gunicorn will work with any python application as long as it is using the WSGI Interface.

## What is Python's WSGI Used For?
WSGI stands for Web Server Gateway Interface and as you can probably guess by the name, it's just an interface to your application that web servers can use to interact with your app.

WSGI is not a web server, it does not offer any kind of logic or processing. It's just a specification of how the interaction between the web server and the application should be conducted.

Unlike languages such as PHP which are meant to serve HTTP requests, python is a multi-purpose language. With python, you can create console applications, desktop apps, web apps and more. This means that there is no "natural" or "obvious" way for a web server to interact with our python application -- until WSGI came along.

When WSGI was introduced, there was finally an interface that we could expect every developer to follow, which in turn allowed us to start creating tools such as Gunicorn or UWSGI that is able to serve any kind of python web app.

Most web frameworks such as Django or Flask takes care of generating the WSGI callable that is used by the web server to serve your application, but for the sake of example let's create our own.

	::python
	def application (environ, start_response):
		response_body = 'Request method: %s' % environ['REQUEST_METHOD']
		status = '200 OK'
		response_headers = [
			('Content-Type', 'text/plain'),
			('Content-Length', str(len(response_body)))
		]

		start_response(status, response_headers)
		return [response_body]

That's it! Pretty simple right? Well, let's summarize what we just did.

- We created a callable (in this case a function) that accepts 2 arguments.
	- `environ` is a dictionary that contains variables and definitions set by the web server.
	- `start_response` is a callback from the web server that we need to execute within our own callable.
- We call the `start_response` callable with a set of headers and an HTTP status.
- We return an iterable that contains our response body. Notice that we wrap our string in a list to make it efficient to iterate through. If we wouldn't then we would iterate through each byte of our string -- which wouldn't be very efficient.

As you can see from our example, WSGI by itself is just a specification of how the callable should look like. We still need an actual web server that calls the callable to fetch a response and then return it back to the client. This is where Gunicorn comes into the picture.

## How to use Gunicorn to Serve Your WSGI App
If you go to [Gunicorn's Website](https://gunicorn.org) you will find the following description of what Gunicorn is:

> Gunicorn 'Green Unicorn' is a Python WSGI HTTP Server for UNIX

What does that actually mean? Does it mean that Gunicorn is a web server similar to Apache or Nginx? If that's the case, then why do we always see one of those web servers being used in combination with Gunicorn?

Let's think back of what WSGI is. It's the Web Server Gateway Interface to our Python application. It helps us define how our application will return HTTP Responses back to the client from our Python app. Gunicorn is what passes the HTTP Requests to WSGI, so in that sense, it works like a web server. But what about other types of requests?

A web application is usually not just made up of a bunch of HTTP requests that return HTML. We also have requests for images, javascript, CSS, PDF's and other static files. Gunicorn doesn't care at all about these requests, it only cares about serving our Python application's responses.

Because of this, Gunicorn **expects you to have another web server** higher up in your infrastructure hierarchy. The idea is that you use something like Nginx to receive requests from the internet, and then you route any application request to Gunicorn -- which is our application server. Any other requests get served by Nginx directly. 

Since Gunicorn never is expected to directly face the internet, it also means that it never needs to handle slow requests. All incoming requests will be sent from the private network or localhost. Because of this Gunicorn itself can be quite simple in its functionality.

### How to Install Gunicorn
Gunicorn is completely built in Python and it can be installed using Python's package manager `pip`.

	::bash
	# There might be a more recent version out 
	# at the point of you reading this article.
	pip install gunicorn>=19.9.0

You will then be able to run it to start serving your application with a single command:

	::bash
	gunicorn foo.wsgi:application -w 5 --bind 0.0.0.0:8000

Let's summarize what this command actually does:

- We use the `gunicorn` command to start gunicorn and we point it to our WSGI `application` callable which is located at `/foo/wsgi.py`.
- `-w 5` flag means that we start 5 Gunicorn workers that will start processing our incoming requests. It's very important to note that Gunicorn works by processing requests in parallel. The recommended worker count depends on the number of CPU cores on your system. The recommended formula is `($CPU_CORES * 2) + 1`
- `--bind 0.0.0.0:8000` tells Gunicorn to listen for incoming requests on that address.

That should be it, at this point you should see something like the following output, which means that you've spawned 5 workers that are awaiting incoming requests.

	::bash
	[2019-09-10 10:22:28 +0000] [30869] [INFO] Listening at: http://0.0.0.0:8000 (30869)
	[2019-09-10 10:22:28 +0000] [30869] [INFO] Using worker: sync
	[2019-09-10 10:22:28 +0000] [30874] [INFO] Booting worker with pid: 30874
	[2019-09-10 10:22:28 +0000] [30875] [INFO] Booting worker with pid: 30875
	[2019-09-10 10:22:28 +0000] [30876] [INFO] Booting worker with pid: 30876
	[2019-09-10 10:22:28 +0000] [30877] [INFO] Booting worker with pid: 30877
	[2019-09-10 10:22:28 +0000] [30878] [INFO] Booting worker with pid: 30878

### Separate Gunicorn Settings into Config File
The command mentioned in the previous section is enough for you to start serving your web application to your visitors in production with only 2 custom settings. But what if you want to configure your Gunicorn server more than that?

Maybe you want to add logging, define timeouts, set thread counts or dig deeper into any of [the other settings](http://docs.gunicorn.org/en/latest/settings.html) that are available for you to set. If you want this then it would quickly get messy to define all of these things as options for the `gunicorn` command.

Gunicorn allows you to create your own separate `myconfig.py` file that can hold all your settings for you. Just create a `.py` file anywhere within your repository and run Gunicorn with the following command instead.

	::bash
	gunicorn -c myconfig foo.wsgi:application

`-c` is the option that allows you to set a path to a config file. In this case, we define it as a python path so it could also be something like `foo.bar.myconfig` if it would be located in `/foo/bar/myconfig.py`.

We could then populate our config with something like this to replicate our original settings.

	::python
	workers = 5
	bind = "0.0.0.0:8000"

## Finding the WSGI Path of my Django Project
Django is a great framework that comes with all the batteries included that we could think off, one of these things is obviously a preexisting WSGI file.

Whenever you initiate your Django project with the `django-admin startproject` command, you will get something like the following file structure.

	::bash
	./
		project/
			__init__.py
			settings.py
			urls.py
			wsgi.py
		manage.py

As you can see, the `wsgi.py` file is already created for you, and it contains an `application` variable that you should point Gunicorn to. With the file structure that we used in the example above, the final Gunicorn command would look something like this:

	::bash
	gunicorn -c config project.wsgi:application

That's it!

## Creating WSGI File of Flask Project
Unlike Django, Flask does not come with as many features out of the box and it does not automatically create a WSGI file for you. With Flask you are expected to define your own file structure and it does not make those decisions for you.

Because of this, we are required to create our own WSGI file that we need to point Gunicorn to be using. Luckily Flask makes this incredibly easy because of its default `Flask()` instance which actually already is a WSGI callable.

Imagine that we have a file structure that looks something like this:

	::bash
	./
		app.py
		config.py
		wsgi.py

- `app.py` is the file that contains your `app = Flask(__name__)` definition. 
- `config.py` is the file that contains your Gunicorn configuration.

All you have to do in this example is to create a `wsgi.py` file and populate it with a single line of code.

	::python
	from app import app as application

We can then point Gunicorn to use our `application` callable with the following command:

	::bash
	gunicorn -c config wsgi:application

You should now be able to serve your Flask application with Gunicorn!
