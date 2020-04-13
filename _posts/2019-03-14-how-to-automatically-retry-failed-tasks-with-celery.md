---
layout: post
title: How to Automatically Retry Failed Tasks with Celery
date: 2019-03-14 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-automatically-retry-failed-tasks-with-celery/
---

Stability of your asynchronous background tasks is crucial for your system design. When you move the work of processing from the main application and instead leverage something like Celery, to execute the work in the background, it's important that you can feel confident that those tasks get executed correctly without you having to babysit it and wait for the results.

There are generally two things that can go wrong as you send a task to a Celery worker to process it in the background.

- Connection issues with the broker and Message Queue.
- Exceptions raised on the worker.

Luckily, Celery gives us the tools and options required for us to control what will happen in these situations so that we can make sure that our worker attempts to retry and execute the tasks again.

## How to Retry Connection to Broker with Celery
The first issue we have is connection issues with the broker. This means that the client can't even send the message itself, which obviously is a crucial problem because that can mean that the message is just gone. 

This is unlike the other kind of problem where the issue happens after the message is sent. In those cases, the message is at least already stored in the queue and can wait there until our worker problems are solved.

This is solved by enabling `retry=True` on the message and also specifying a  retry-policy to define how the retries are executed.

Note that this can be applied both on `task.apply_async()` and on `celery.send_task()`, so it can be done both on calls to local tasks but also to remote tasks stored in other code bases.

Here's an example of how we can enable retry and set a retry policy:

```python
from tasks.celery import app

app.send_task(
    "foo.task",
    retry=True,
    retry_policy=dict(
        max_retries=3,
        interval_start=3,
        interval_step=1,
        interval_max=6
    )
)
```

What this means is that if the connection fails and we cannot send the message to the message queue, we will attempt to retry 3 times. The first retry will happen at `interval_start` seconds, meaning 3 seconds. Then each additional failure will wait for another `interval_step` 1 second until it attempts to send the message again.

Note that these type of retries only happens when it fails to send a message, it does not happen when the task itself fails and ends up with a `FAILURE` state.

If you want to enable retry policies globally throughout your application you can also set it in your [Celery settings](http://docs.celeryproject.org/en/latest/userguide/configuration.html#std:setting-task_publish_retry).
	
## How to Retry Failed Tasks in Celery
The next type of issue that we might run into where we also want to leverage retries is when tasks fail. Note that this scenario is completely different than the first one. In the first case, we *failed to send the message*. In this case, we *fail to execute the task successfully*.

The reason why a task might fail is usually that a crash happened on the worker and an Exception was raised. Perhaps there is a bug in the code, some service timed out or it was too high demand.

Unlike the first scenario where we told the client to retry to send the task again, this time we want to add the code to the task itself, meaning, it will be the worker that retries to execute the task, not the client that retries to send the task again. Note this significant difference.

Here's an example of how we can retry a task when an Exception is raised:

```python
import logging
from tasks.celery import app

logger = logging.getLogger(__name__)

@app.task(name="foo.task", bind=True, max_retries=3)
def foo_task(self):
    try:
        execute_something()
    except Exception as ex:
        logger.exception(ex)
        self.retry(countdown=3**self.request.retries)
```

Let's go through what all of this code do:

- `bind=True` gives us access to the `self` keyword argument.
- `max_retries` defines the maximum times that this task can be re-executed using the `self.retry()` method.
- Whenever we catch an exception that we do not re-raise and silence, we want to make sure that we log the error using the `logger.exception()` method which will include the full traceback.
- `self.retry()` will retry the task. The `countdown` kwarg defines how many seconds we should wait before we retry again. Note that we define it as an exponential value that gets increased by each retry.


## Summary of Task Retries
As I stated at the beginning of this article, there are two types of retries that we might need to do in Celery, the first one is retrying the message sent from the client, and the other one is retrying execution of the task on the worker.

It's important that you understand the differences between the client that sends the message, and the worker that executes the message, and each of their responsibilities, to make sure that you can come up with the optimal solution to any issues you might have. 

The client is *only* responsible for sending messages and handling responses, and the worker is *only* responsible for picking up messages from the queue, executing tasks and returning responses. 

I've personally made the mistake in the past where I've mixed up the responsibility between the client and the worker, and instead of implementing the task retries on the worker side, I did it on the client side by awaiting the responses and resending the message if it failed. This quickly became ugly and quite a bad solution. Lesson learned.