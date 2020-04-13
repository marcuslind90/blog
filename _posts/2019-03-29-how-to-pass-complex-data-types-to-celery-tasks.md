---
layout: post
title: How to Pass Complex Data Types to Celery Tasks
date: 2019-03-29 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-pass-complex-data-types-to-celery-tasks/
---

Sometimes some of our favorite tools make things so simple for us by abstracting away so much of the technical implementations, that we lose track of what is actually going on behind the scenes, which cause us to accidentally implement things incorrectly and have unintended bugs within our code.

I ran into one of these bugs a few days ago with Celery. I had a Celery task that accepted a deserialized yaml file as a dictionary, it then modified some of these values and stored it again in yaml format. The bug was that throughout this process parts of the yaml code was being changed without intention.

Isn't that weird?

Imagine the following code:

	::python
	import yaml
	
	@app.task
	def foo(options: Dict[str, Any]) -> str:
		return yaml.dump(options)

	foo.delay(options=yaml.load("from: 2019-01-01")

What do you expect the final YAML to be in the code above? Shouldn't it just be the original yaml string? Isn't it same as doing the following?

	::python
	import yaml

	yaml.dump(yaml.load("from: 2019-01-01"))

The answer is: No! It is not the same thing. The differences between these two methods are because of all the things that Celery abstract away from us.

## How does Celery Pass Data to Worker?
Remember, all Celery does is sending messages to a message queue and then having a worker that pick up these messages to execute them.

The messages are stored as text, so even if we're passing data types such as integers, strings, dictionaries, lists or dates, all of them will have to be stored as text while they are within the message queue.

So what this means is that when we're doing something like:

	::python
	foo.delay(options=dict(from=datetime.date(2019, 1, 1)))

What we're actually doing is the following:

- We serialize the dictionary to a JSON string.
- We pass the kwargs with its meta data to the message queue as text.
- The Celery worker reads the message and its meta data.
- The Celery worker detects that it was serialized as JSON and deserializes it.
- The Celery worker passes the deserialized values to the task.

To make things simple, Celery abstract away all of this and handles it for us automatically. This might make it appear like we can pass dictionaries, dates or objects to our tasks but in reality, we are always simply passing messages as text by serializing the data.

## Limitations of JSON
So back to the bug, what actually happens in our code example above? Well, actually Celery will serialize our `datetime.date` object to a string, and then YAML will no longer know that it is a date object, and just treat it as a string from that point.

So we might pass in `datetime.date(2019, 1, 1)` but we might get back `"2019-01-01T00:00:00"`. This is because JSON has quite a lot of limitations of what data types it can recognize. 

JSON actually only recognizes the following data types:
- `Dict`
- `List`
- `str`
- `bool`
- `int`
- `float`
- `None`

Anything else (such as `datetime.date` will be serialized to a string and never be deserialized back to its original form. To solve this, we have two options:

- Don't pass in an object that JSON does not support. In this case we could convert our date to a timestamp and pass in an integer.
- Change serializer to a serializer that supports the data type we're passing.

In our case, since we are using yaml, it makes sense to switch to the yaml serializer for our call.

## Setting Celery Serializers
By default, Celery uses a JSON serializer to serialize all of our arguments to our tasks into a text message that can be passed to the message queue. 

You can customize this to use other serializers by specifying the following settings:

- [accept_content](http://docs.celeryproject.org/en/latest/userguide/configuration.html#accept-content)
- [task_serializer](http://docs.celeryproject.org/en/latest/userguide/configuration.html#task-serializer)

The `accept_content` setting is used by the worker to determine which types of serializers that the worker is allowed to deserialize. This can be used for security purposes, you might not always want all types of serializers to be used. 

The `task_serializer` setting is used by the client to determine how it should serialize the data before it passes it to the message queue.

On top of that, you can also specify the serializer on a task-call level instead of setting it for the whole system. For example, you might use `json` by default but in a few other cases use `yaml` or `pickle` to serialize your data.

	::python
	# Override default serializer and use yaml instead.
	foo_task.apply_async(kwargs=data, serializer="yaml")

### Which Serializer Should I Use?
Celery comes with [4 different serializers](http://docs.celeryproject.org/en/latest/userguide/calling.html#serializers) out of the box.

- json
- yaml
- pickle
- msgpack (Experimental)

There is no "right" choice between all of these, they have different benefits and they should be set based on the type of messages that you send within your application.

Personally, I think it's a good choice to use JSON as the default since it has the best performance, and then complement it with YAML for certain cases where you might require passing more advanced data types.

Here is a summary of each serializer's benefits/downsides:

#### JSON Serializer
Benefits:

- Quick/Good Performance.
- Works well across programming languages. 

Downsides:

- Limited support for data types.

#### YAML Serializer
Benefits:

- Support a larger range of data types than JSON.
- Works well across programming languages.

Downsides:

- Slower than JSON

#### Pickle Serializer
Benefits:

- Support any data type
- Relatively fast

Downsides:

- Does not work across programming languages.
- Security risk since it allows to pass any python code.
