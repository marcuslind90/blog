---
layout: post
title: Best Practices for Setting Up Celery with Django
date: 2019-01-23 00:00:00 +0000
categories: docker
permalink: /@marcus/best-practices-for-setting-up-celery-with-django/
---

Asynchronous Celery tasks can be a great solution to many problems that you might encounter when you're building a Django application. It allows you to move the processing of long running tasks to the background, and continue serving the visitor their HTTP request without having to wait for the long running task to finish.

For example, a few months ago I was working on a project where we had a step by step wizard where we collected a lot of data from the users. In the end of the process we generated a ton of data from all the inputs that the user provided. The process of generating the final data took ~15 seconds or so, so when the user submitted the final HTML Form, the HTTP requests took "forever" (15 seconds is forever in the web world!) to finish.

This was a perfect example of when it is a good time to leverage asynchronous tasks using Celery. When I installed Celery, I was able to let the final HTTP Form Request finish in just a second, because all it did was sending a message to a message queue to inform our Celery worker that it had to generate the user's data, and then the actual processing was happening asynchronously in the background. The user experience was massively improved.

Celery by itself is not dependent on Django. You can setup Celery with any kind of Python application, however it comes with some really handy features with Django in mind which makes the integration very straight forward and simple to do.

## Installing Celery
The first step you have to do is to install the Celery package using `pip`.

```bash
# Note that there might be a more recent
# version released when you're reading this.
pip install celery>=4.2.1
```

The next step would be to setup a file where we instantiate our `Celery` instance.
Create the following file structure:

```bash
./
    tasks/
        __init__.py
        celery.py
```

Start off by populating the `celery.py` file with the following information:

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'project.settings')
app = Celery("tasks")
app.config_from_object('django.conf:settings', namespace="CELERY")
app.autodiscover_tasks()
```

Let's summarize what we're doing here:

- We set a default value for the `DJANGO_SETTINGS_MODULE` environment variable to be the python path to our settings file. This environment variable is used by Django to define which settings file it should load and it will allow us importing the settings with `from django.conf import settings`. 
- We instantiate the `Celery` instance to `app` variable and name our Celery application `"tasks"`.
- We load the Celery config values from the `settings` object within `django.conf`. This is where we will expect all of our configuration to be set. The `namespace="CELERY"` means that we expect the configuration values that are related to Celery to be prefixed with `CELERY_` so that it does not clash with other Django settings.
- We use `autodiscover_tasks()` to tell Celery that it should use the `settings.INSTALLED_APPS` list of applications to find defined Celery tasks. This allows us to split out the tasks throughout our project's code base where they logically belong.

The next step is to populate the `__init__.py` file with the following code, which will allow us to automatically import the `Celery` `app` instance that we defined.

```python
from .celery import app as celery_app

__all__ = ("celery_app", )
```

### Configure Celery to use RabbitMQ
In the previous step we informed Celery that it should load all of its configuration values from the default Django project settings with the caveat that all of the Celery specific configuration values should be prefixed with `CELERY_`.

So let's quickly just summarize what Celery actually does when we want to trigger an asynchronous job. 

- The Celery application sends a message to a "broker" which is a message store or message queue that holds all of our messages.
- A Celery worker then awaits the messages from the "broker" and then reads it and trigger a task that the message informs the worker to execute.

As you can see, the "broker" is a very key board of our infrastructure when it comes to working with Asynchronous tasks in Django. It's the part that holds all of the messages that the client sends, and that the worker pickup.

Celery allows us to use many different type of brokers such as:
- RabbitMQ
- AWS SQS
- Redis

I personally prefer to work with RabbitMQ and it is what I will use in this article. If you're in the Amazon Web Services environment or if you already have a Redis instance, you can very easily use any of the other brokers that Celery supports.

So let's tell Celery that it should send and read messages from a RabbitMQ Broker by adding the following to our Django Settings file:

```python
BROKER_USER = os.environ.get("BROKER_USER")
BROKER_PASSWORD = os.environ.get("BROKER_PASSWORD")
BROKER_HOST = os.environ.get("BROKER_HOST")
BROKER_PORT = os.environ.get("BROKER_PORT")
BROKER_VHOST = os.environ.get("BROKER_VHOST")

CELERY_BROKER_URL=f"amqp://{BROKER_USER}:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/{BROKER_VHOST}"
```

The key point here is the `CELERY_BROKER_URL`. It is the connection URL that we use for sending and reading messages. In our example its made up by variables that are read in from our system environment variables. In your own case you need to either define these environment variables, or replace each `os.environ.get` line with your own hard coded values.

## Running the Celery Worker
The final part of setting up Celery is to actually execute and run the Celery Worker which is what will execute the background jobs that your application sends to the RabbitMQ message queue.

This is easily done with a single line of code that is executed in the terminal:

```bash
celery -A tasks worker -Q celery
```

To summarize what this command does:

- `-A` allows us to define which Application that we want to run. Remember that we defined our application as `app = Celery("tasks")`? The name of our application is therefore "tasks".
- `worker` just means that we want to execute the worker command of Celery and spawn a worker.
- `-Q` tells the worker which queue it should listen to. By default Celery will send its messages to the `celery` queue, but you could configure it to send it to a queue with another name. 

At this point your worker should be up and running and waiting to execute tasks.

### Running the Celery Worker as a Daemon/Background
A problem with just using the command above when you're starting your Django application is that a lot of the times you want to chain that command with running your Django web server either by `python manage.py runsever` or by packages such as `gunicorn`.

If you would start your application with the following command:

```bash
bash -c "celery -A tasks worker -Q celery && python manage.py runserver"
```

Then the second command would never execute, because the `celery worker` command would never finish running. So what you want to do is to execute the Celery worker as a background job by itself on your system. 

There are plenty of ways to Daemonize a command or executable in Linux and there might not be a single "correct" way. If you're already familiar with your own methods to do this then go ahead and do whatever you feel comfortable with.

Personally, I love doing it using the popular [supervisor](https://github.com/supervisor/supervisor) package that can be installed with `pip`. This package allows us to simply define a configuration file with different tasks that we want it to execute in the background and keep running, and it will manage it all for us.

A great benefit of this is that you can bundle all of this together with your application, instead of having to set it up on the system outside the scope of the application itself.

#### Installing Supervisor
As mentioned above, you can install supervisor using `pip`.

```bash
pip install supervisor>=3.3.5
```

Note that at the time of writing this article, the supervisor package only work on Python2.7. Supervisor is currently working on releasing a version that will be running on Python3 and you can already use it by installing it directly from Github.

```bash
pip install git+https://github.com/Supervisor/supervisor
```

After you've installed it you have to create a config for it. You can get a default config by running the command `echo_supervisord_conf` after you've installed the package. This will write out a complete config into your terminal and you can copy it to your own `supervisord.conf` file in the root of your repository.

At the end of this configuration file, we want to add the configuration that informs our Supervisor command that it should run our Celery Worker as a background task.

```bash
[program:celery]
command=celery -A tasks worker -Q celery
stdout_logfile = /tmp/celery.log
redirect_stderr=true
```

Finally we need to run supervisor with the following command:

```bash
supervisord -c supervisord.conf
```

Note that the command is called `supervisord` unlike the package which is called `supervisor`. The `-c` flag allow us to define a file path to the `supervisord.conf` configuration file that it should use.

This would then allow us to run our Django application by first starting `supervisord`, and then running our Django application.

```bash
bash -c "supervisord -c supervisord.conf && python manage.py runserver"
```

A final note is to remember that during development, unlike Django's `runserver` command, Celery will not automatically pickup new code changes as they are saved. You need to restart the worker for it to find new tasks or changes to existing tasks.

## Creating Our First Task
Great job! At this point you're done with the installation of Celery and you should have a running Celery worker that awaits any incoming messages to your RabbitMQ message queue.

Now its finally time to create a sample task that we can use to illustrate that its all working.

```python
from tasks.celery import app as celery_app


@celery_app.task(name="foobar.sample_task")
def sample_task(value):
    print(value)
```

This code could live within any application that is loaded into your Django Settings `INSTALLED_APPS` list of applications. I suggest that you create a dedicated `tasks.py` for each application to separate the tasks to its own file and to easily keep track of them.

Note that the task itself will not be executed from our Django process, it will be executed by our Celery Worker that we created as a background job using `supervisord`. This means that the `print(value)` statement will result in it printing out the value inside the Celery Worker process. Not within our `./manage.py runserver` process.

## Calling Our Task
Finally we've arrived at the moment we've all been waiting for! Its time to call our first task. Celery allows us to call tasks in multiple different ways, but one of the most simple way to do it is using the `delay()` method.

Let's say that we would like to call our `sample_task` from within a Django View.

```python
from django.views.generic import View
from django.http.response import JsonResponse
from foobar.tasks import sample_task


class SampleView(View):
    def get(self, *args, **kwargs):
        # Call our sample_task asynchronously with
        # our Celery Worker!
        sample_task.delay("Our printed value!")

        return JsonResponse(dict(status=200))
```

Now when we visit our `SampleView`, it should automatically send the task to our Worker and the Worker process should print out `"Our printed value!"`. 

In some cases you might not have access to your tasks because they might live in another code base. If that's the case you should read my article about [calling remote tasks with Celery](https://coderbook.com/@marcus/how-to-send-celery-messages-to-remote-worker/).

## Awaiting Results
In the previous section I showed you how you can send a message to the worker that will execute a task. But the client (our Django application) doesn't get any response or information if the task failed or succeeded. At this point in time we can't even receive a response back with data.

Imagine that we have some task that perhaps upload some file for us. When the process is done, our Django application will probably want to receive the file path to the uploaded image. How do we pass that back to our client who send the message?

On the Task side its pretty simple. All you have to do is to return the data with a `return` statement. For example we could rewrite our task to the following:

```python
@celery_app.task(name="foobar.sample_task")
def sample_task(value):
    return value
```

Instead of printing the value we send to it, it will now simply pass it back to us. But that's not enough, we also have to tell Celery how it should pass back this information. We can do that by defining a result backend.

### Defining a Result Backend
The thing that actually controls how our results are stored or returned is something that Celery calls a "Result Backend". Celery supports multiple different types of backends such as storing the result in a database, a reddis instance or just passing it back through the `amqp://` protocol using the `rpc` backend. 

All of these basically achieves the same goal, which is to keep track on results of tasks, but each one achieve the goal in a different manner using different technologies. 

Remember that I told you earlier in the article that Celery have some nice tools for us Django users that make integration extra convenient? Well one of these tools is the [django-celery-results](https://github.com/celery/django-celery-results) package that you can install using `pip`. 

What it does is that it provides a result backend for us, that will store things within the Django Database using a `Task` model that it defines. We can then easily lookup the results within the database using the normal Django ORM or even use things such as Django Signals to do actions when Tasks changed state.

#### Installing Django Celery Results Backend
The installation of Django Celery Results package is very simple and straight forward.

```bash
pip install django-celery-results>=1.0.4
```

The next step is to add it to your `INSTALLED_APPS` setting so that Django knows about its models and how to represent them in the database.

```python
INSTALLED_APPS = [
    ...,
    'django_celery_results',
]
```

Finally we have to define Celery's `RESULT_BACKEND` setting to use our new django-celery-results backend. Since we load our Django settings to our Celery app, we define this value within our `settings.py` file.
	
```python
CELERY_RESULT_BACKEND = 'django-db'
```

Make sure that you run `python manage.py migrate` to migrate the package's models to your database and restart your application and worker. You should now be done with installing your Django Celery Results Backend!

#### Follow up on results in Django Admin
You should now be able to trigger the task again by visiting the view that we defined in the section above, and the Celery Worker will now send the results back using the Django Celery Results backend that we added.

You can login to the Django Admin and there you will see a new "Tasks" section. If you go into this section you should see your latest Task being listed there with its results and state.
