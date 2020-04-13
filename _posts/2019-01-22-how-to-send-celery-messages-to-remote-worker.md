---
layout: post
title: How to Send Celery Messages to Remote Worker
date: 2019-01-22 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-send-celery-messages-to-remote-worker/
---

When you're setting up a distributed system where there are multiple different applications and services that communicate with each other, you can choose to handle this communication in a few different ways.

One of the ways you can communicate between services while keeping them decoupled is by sending messages to Message Queues that other services pickup and execute. For example, imagine we have a web application that allow the user to upload videos. To optimize the delivery and performance of streaming the videos we might want to turn the files into a new codec or format. 

The task of turning the video files into another former might be the responsibility of a second service that is decoupled from our web application. So after the user has uploaded their file to our storage, we would have to tell this second service that it should start processing the uploaded file.

We could achieve this by the web application sending a message to the worker of the second service with the file path to the file that require processing, and we can then allow this process to happen in the background while we keep serving our visitors their web requests from our web application service. Great, right?

One of the more popular tools to use to manage these kind of messages is [Celery](http://www.celeryproject.org/).

## Why use Celery instead of custom worker?
One of the projects that I recently worked on the team required this kind of message processing and we decided to create our own custom worker using the messaging library `pika`.  The idea of writing your own solutions is always quite seductive to programmers, but in the long run it is hardly ever the right choice -- unless you have some very specific, custom needs.

Pretty soon we ran into some stability issues. Sometimes messages timed out, other times we had threading problems and in general it was just quite difficult to debug and solve some of the bugs that our custom worker had. I then suggested to the team that perhaps it was a better idea to switch to a solution that would be stable and ready for use out of the box -- Celery.

Why waste our time maintaining our own tools when all we really want is just something that can send, receive and process messages? It is pretty straight forward and it definitely doesn't require any kind of custom solution. Add to this the fact that Celery got 10'000+ commits, hundreds of contributers and is widely used by the Django and Python community in production environments, and it starts to look attractive pretty fast.

We replaced our custom code and since then we haven't looked back.

## Difference between Local and Remote Tasks
Most projects are not distributed systems. Most projects just involve a single application with a single code repository. This makes it quite easy to import and execute Celery tasks in the following manner:

	::python
	from tasks.celery import app
	

	@app.task
	def sample_task(value):
		print(value)
	
	sample_task.delay("Foo")
	
We can simply just import the `sample_task` function and add `.delay()` to it to invoke it as a background task that gets executed on our worker. But what if you don't have access to the code where the task is defined? What if it lives in a completely different repository and code base?

In the case of a distributed system with multiple different applications and repositories, each repository might have its own Celer Worker and its own tasks. You can't use python to import the task from one code base to another.

The way you call tasks in this situation is by its name in string format.

	::python
	from celery.tasks import app
	
	
	app.send_task("sample_task", kwargs=dict(value="Foo"))
	
This results in the exact same action as the first example on top, but we don't require the actual function to be imported into our code. Instead we can just call it as a string. Note also that we can pass in any keyword arguments using the `kwargs={}` parameter.

## Route Tasks to Different Queues
In the case of our example with a distributed system, we might actually want to run multiple workers at the same time. Maybe we have Worker A for Service A, and Worker B for Service B. How do we make sure that each worker doesn't pickup each others tasks?

For example, imagine that we send a message to invoke the `sample_task` defined in the section above, but the task only exists within Worker A. What would happen if Worker B pickup the message first? It would raise an error and claim that the task hasn't been registered yet and that it can't find the task. 

The solution to this is that we separate the queues depending on which Service or Worker that is supposed to process it. We could have a `"worker_a"` queue and a `"worker_b"` queue, and Worker A only listen to messages from `"worker_a"` while Worker B only listen for messages on `"worker_b"`.

But how do we then make sure that each message gets send to the right queue? Its called "Routing".

### Route Messages to Queues based on Task Name
Celery allows us to define `task_routes` where it will route messages to different queues depending on the name of the task. But this would first require us to have some kind of pattern to our naming convention of tasks, so that we could identify and create rules for which tasks that should go where based on their names.

My own preference is to prefix each task name with the service or application name. E.g. instead of defining the task in the way we did in the first example, we could do it in the following manner.

	::python
	from tasks.celery import app
	
	
	@app.task(name="web.sample_task")
	def sample_task(value):
		print(value)
		
Notice that we added a `name=""` parameter to our task with a custom name that is prefixed with `web.`, which in this case would represent our Web Application.

By doing this we could simply add a `task_routes` configuration that makes sure that all of the tasks that is prefixed with `web.` goes to the `web_queue`. 

	::python
	app = Celery("proj")
	...
	app.conf.task_routes = {
		'web.*': {'queue': 'web_queue'}, 
		'remote.*': {'queue': 'remote_queue'}, 
	}
	
If we then have a web worker that is listening to the `web_queue` queue, and a remote worker that is listening to the `remote_queue` queue, we would always be sure that the correct worker receive the correct message.

## Setting up a Result Backend
The setup so far would only allow us to send messages to workers in a distributed system. But what about following up on the results? Right now we would just be sending out messages without knowing what ever happens to them. Did they succeed or fail? What values did the message return?

The way Celery keep track on the results and status of messages is by defining a "Result Backend". The result backend defines how and where Celery should store the meta data of the task. This could be in a database such as PostgreSQL and Reddis, or it could simply be by returning data back to the client through the `amqp://` protocol.

If you only have a single worker that is part of the rest of your application, I suggest that you use a `database` backend or the [django-celery-results](https://github.com/celery/django-celery-results) so that you can store the data within a database or easily setup Django Signals to trigger callbacks whenever a task is successful in a clean manner. 

However, if you have multiple workers in a distributed system it is important to note that each worker **must use the same result backend**. Unless the client and the worker use the same result backend, the client will never receive any response or result from its messages.

Since all workers in a distributed require the same result backend, it means that whatever backend you choose it must be available across your complete system. This could add some tighter coupling between your services that you might not wish for. Because of this I prefer using the `rpc` backend, which means that any response will be returned across the `amqp://` protocol back to the client that send the message. 

By doing this, it means that your client can determine what to do with the response manually, instead of automatically storing results or responses within a database or redis instance.

You define the `rpc` backend with the following configuration

	::python
	CELERY_RESULT_BACKEND = 'rpc'

## Summary
Throughout this article we have learned a few different things of how to properly setup Celery to work in a distributed system where we might have multiple different workers that process tasks that are spread out between multiple codebases. What we can learn from this is the following:

- Define a queue per worker type so that the correct tasks only get picked up by the correct worker.
- Route messages to queues based on their names. Make sure that your tasks got prefixes so that its easy to define router rules.
- Use a `RESULT_BACKEND` that is available across your whole system. If you want to keep things decoupled and not rely on some kind of global storage, then use the `rpc` backend which will return the results back through the `amqp://` protocol.
