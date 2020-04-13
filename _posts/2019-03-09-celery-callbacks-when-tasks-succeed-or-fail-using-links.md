---
layout: post
title: Prepare for the Software Engineering Phone Interview
date: 2019-03-09 00:00:00 +0000
categories: docker
permalink: /@marcus/celery-callbacks-when-tasks-succeed-or-fail-using-links/
---

Reacting on calls to Celery tasks is one of the first things that you will want to dig deeper in as soon as you start scratching the surface of Celery. How do you react on when a task finishes or fails, and then trigger some other code when these events occur?

For example, I was working on a project recently where we leveraged Celery to do asynchronous communication between services in a distributed system. We had multiple applications that were split up in multiple repositories and deployed on multiple different cloud instances.

In my use case for this project, I was sending a message to a RabbitMQ Message queue to trigger some processing of files stored on the cloud. This processing could take 10-30min depending on which files we were talking about, and sometimes the processing on the other end even crashed because the files were in some wrong format that had been missed during validation.

When the task to process the files finished, I wanted to call some callback to trigger new actions and update the state of my own local application database. For example, I wanted to update the status to `SUCCESS` so that I could continue on with my business flow and use these newly processed files, or I wanted to update the status to `FAILED` in case of failure, so that I could display that with a notification to the user, so that they could fix the issue and restart the processing.

How did I achieve this? How did I chain my celery task so that it called other tasks as callbacks whenever the task finished or failed? I used something that Celery call "Links".

## Using Link and Link Error Callbacks with Celery
When you're using Celery, a lot of times it basically comes down to using the `Task.apply_async()` or `Celery.send_task()` methods. These have almost identical method signatures and take the same arguments.

The main difference between these methods is that you use `apply_async()` on a task that you can import from within the same code repository, while you can use `send_task` to call tasks remotely from other applications where you might not have access to the actual task as a python import.

For the sake of simplicity, I will use `send_task()` in my code examples below.

### Celery Link Callbacks
`link` is an argument that you can pass into your `send_task` or `apply_async` tasks. You set this to a task signature, and then this signature will be called whenever the task executes successfully.

For example.

```python
@app.task
def success_callback(response):
    print("Processing task finished successfully!")

app.send_task("remote.processing", link=success_callback.s())
```

A few things to note here:
- The `success_callback` task receives a `response` kwarg, but we are not passing it any value when we set its signature to the `link` parameter. So how does response get passed in?
- What is `.s()`? It is a way to define a [signature](http://docs.celeryproject.org/en/latest/reference/celery.html#celery.signature) of a Task.

The first thing is explained by the fact that Celery always passes in the response of a previous task to the next task chained through the `link` argument. So whatever `remote.processing` returns, it will be passed in as a first argument to the `success_callback` task.

The second point regarding Signatures is a pretty crucial thing to understand about Celery. `Signature` is a returning topic and it's important to have a solid understanding of what they are. 

Basically, a signature is a definition of a task call. This means that it defines what task to call and what arguments to pass to it, but it's not actually calling the task yet. Does that make sense?

By defining a signature, we can define in the present, what call we want to call in the future. Confusing? Well, let's imagine that we are calling a remote task that is located on a different system, and it has no understanding of our own system. They are completely decoupled.

When we define a chained task using `link`, what we are actually doing is telling our remote system to call the task defined in `link` whenever it's done. So it is the *remote* system that is calling the task defined in `link`, not the system where the `link` is being set.

So let's say that we extend our previous example to look like this:


```python
@app.task
def success_callback(response, file_id):
    file = File.objects.get(pk=file_id)
    file.status = "SUCCESS"
    file.save()

file_id = 1
app.send_task("remote.processing", link=success_callback.s(file_id))
```

In this example, the `remote.processing` has no concept of our applications database and model structure, so it might not even know that there is a `File` model. But still, it will know which ID to pass back to the `success_callback` because we pass it a pre-defined signature that contains it. The signature was defined on the origin system but called from the remote system.

### Celery Link Error Callbacks on Exceptions
So the normal `link` argument is passed into the `send_task()` method to define the next task that should be executed whenever the first task finishes. So what about if the first task never finishes or crashes? Can we set up a callback for this?

Let's say that the worker raises an exception and it never finishes processing of our file. We would probably want to catch this so that we can notify our user that the file wasn't able to be processed. This can all be achieved with the `link_error` argument.

Similarly to the normal `link` argument, you pass the `link_error` argument a `Signature` that defines which Celery task it should call when an error occurs. There has been a lot of confusing about this topic though, since the behavior is quite different than the normal `link` argument.

#### Using Link Error Tasks With Remote Worker
Unlike the `link` signatures which gets called as tasks and passed back into the queue and picked up by any available worker, the `link_error` arguments gets called directly by the worker. This has a major impact if you have multiple code bases with multiple workers that are responsible for executing different tasks.

For example, imagine that System A calls a task in the following manner:

```python
from .tasks import error_callback
app.send_task("system_b.foo", link_error=error_callback.si())
```

As you can see, the `error_callback` task is defined on the client side from where we call the task. What will happen here is that if `system_b.foo` task fails, it will attempt to call `error_callback` from its own worker, which will raise an `NotRegistered` error since the task is not defined within the System B's worker.

You will never run into this error if you are running tasks on a single worker where all tasks are defined, but if you have a complex system with multiple services and systems that work together and communicate between each other using Celery, this will definitely be an issue that you will run into.

There is a hacky solution to this though. By defining the `link_error` callbacks as a chain of signatures, it will force the worker to call them as tasks and send them back to the queue instead of calling them directly.

So you could do something like this:

```python
from .tasks import error_callback
app.send_task("system_b.foo", link_error=(error_callback.si() | error_callback.si())
```

Ugly? Yes. Hacky? Yes. Does it work? Yes.

To clean things up and avoid confusing to other developers, I suggest that you separate this into a utility function with a dummy task (to avoid calling the same signature twice).

```python
@app.task
def dummy():
    """Dummy task that does nothing to be used in error util function"""
    pass

def force_error_task(signature: Signature):
    """Turn signature into chain, to force delayed calls of task"""
    if not signature.immutable:
        raise ValueError("Signatures in callbacks should be immutable)
    return (signature | dummy.si())
    
app.send_task("system_b.foo", link_error=force_error_task(error_callback.si()))
```

Note the use of `.si()` instead of `.s()`. The difference between these two methods to create a `Signature` object is that `.si()` makes the signature immutable.

#### Using Link Error Tasks with Single Worker
The above section described what tricks you have to do to be able to work with link callbacks in a distributed system where there are multiple different services and multiple different workers that communicate with each other.

In most applications, this is not needed and normally the infrastructure will be simpler than this. If you only have a single worker in a single system where all tasks are local and accessible as imports, you can take advantage of the `link_error` callbacks in easier and simpler manners.

In this case, you can treat it similar to the `link` argument with one major difference. Since `link_error` is being called when the task does not finish properly, it means that it cannot be passed a response from the previous task. Instead what you get passed into it is the Task's `request`, `exc` and `traceback` arguments which contain the error information regarding the raised exception.

For example you could do something like this:

```python
@app.task
def log_error(request, exc, traceback):
    logger.error(f"{exc} - {traceback}"

foo_task.apply_async(link_error=log_error.s())
```

## Awaiting the Response Synchronously
A note that is worth to mention is that you do not necessarily need to call a Celery task asynchronously and respond to it with Callbacks, Celery allows you to await the response and block any other execution while doing so. Meaning, it treats the task as a normal synchronous call.

This can be achieved using the `Task.get()` method.

```python
@app.task(name="foo_task")
def foo():
    return "bar"

# Call asynchronous
response = app.send_task("foo_task")
print(response)  # <AsyncResult>

# Call synchronous
response = app.send_task("foo_task").get()
print(response)  # "bar"
```

This might look at bit weird to you, why would we want to leverage Celery if we want to await the response in a synchronous manner? Isn't the whole point of using Celery to use it with processes or tasks that take too long to execute synchronously and instead we want to do it as a background task and get the result later?

Well yes, but that's not the only use case. Sometimes you might want to treat the Celery tasks as just normal API endpoints that are remote and return some type of response instantly. For example, you might reach out to some other service to get some kind of data, or maybe you run some quick validation or checks remotely. These tasks usually execute within milliseconds and it could be a good idea to await the response instead of over complicating things and treating the response asynchronously.
