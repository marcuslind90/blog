---
layout: post
title: How to make Singleton objects in Python
date: 2020-04-23 00:00:00 +0000
categories: python
---

Singletons are a quite common pattern in software engineering that means that you create
a class that can only be instantiated once, there can ever only exist a single instance
of the class. 

Why would this be useful? Well in one of my recent projects that I worked on, I built a 
`Context` class that would hold meta data about the current execution of a pipeline. It
included things like unique id's, timestamps and more.

It was very important that there would only ever exist a single `Context` throughout the
codebase, it would be quite confusing if someone in my team instantiated their own with
different id's and timestamps than other places in the code.

So how did I ensure that there could ever only be a single `Context` instance throughout
our codebase? By using the Singleton pattern.

## What is a Singleton?

Let's illustrate the functionality of a Singleton by writing a simple unittest that we
want to hold true by the end of this article.

```python

class SingletonTestCase(unittest.TestCase):

    def test_singleton(self):
        c1 = Context({"foo": 1})
        c2 = Context({"foo": 2})
        # Both variables point to the same object,
        # there is only a single instance of `Context`.
        self.assertTrue(c1 is c2)

```

Note that we are asserting the equality of our instances using the `is` keyword instead
of the `==` operator, this means that we are literally checking if they are the **same**
object, and not only checking if they are *equal*.

So, what does this unittest show us? It illustrates that even though it appears that we
are creating 2 different contexts, `c1` and `c2`, we are actually still only creating one.

If we modify the values of `c2`, we are also modifying the values of `c1`, since they
are the same object.


## When would you use a Singleton pattern?

As mentioned earlier, you would use a singleton when you only ever want it to exist a
single instance of a class that is **shared** throughout multiple sections of your code.

This is usually because you only want it to ever exits a single source of truth of the
data that the class holds and avoid outdated or modified versions of it.

Some examples of when a Singleton **might** want to be used:

* Settings or Configurations of your application. You might have a class that holds your
  credentials, log configuration, endpoints and more. It might make sense that it can
  ever only exist a single set of settings for your application and not multiple versions
  floating around at the same time.

* HTTP Requests. If you are building something web related that executes on web requests,
  it might make sense to create a Singleton for your `Request` class to make sure that there
  is a global, single request that can be imported and used throughout your codebase.

* Loggers. You might want to have a single logger instance available throughout your codebase
  that can be shared and where you can feel confident that it always remains the same. 


## Making a Singleton in Python

So let's finally get to creating our Singleton. It is actually quite easy, what we
want to make sure is that if an instance already exists, then simply just return the
first instance whenever anyone attempts to create a new instance.

For example:

```python

class Context(object):
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super(Context, cls).__new__(cls)
        return cls._instance

```

So, what are we doing here?

* We define a **class level variable** named `_instance` that holds the instance of
  our class when it is created.
* When anyone attempts to create a *new* instance of our class, we first check if an
  instance already exists, if not then we create one and return the instance.

You probably have 2 follow up questions.

* What is **class level variables** vs **instance level variables**?
* What is the difference between `__new__` and `__init__` in Python?


## Class level variables vs Instance level variables in Python

So how come it works to use `_instance` in our example above? Wouldn't every instance of
our class have it set to `None` at the start? How can the value be shared across calls?

Most of the time, you probably define your variables in a class using the `self.x` syntax.

```python
class Foo:
    def __init__(self):
        self._instance = "Foo"
```

This is what we call an "instance level variable". The variable exists on the **instance**
of the class. If you have 10 different instances, you might have 10 different values.

However, if you define your variable as we did above, without the `self` prefix, we are
creating a **class level variable**. Unlike an instance, this variable is defined on the
class itself and every instance that is created out of that class will share the same value.

We can illustrate that with the following example:

```python
class InstanceLevel:
    counter = 0
    def __init__(self):
        # self.counter is on an instance level.
        self.counter += 1

class ClassLevel:
    counter = 0
    def __new__(cls):
        # cls.counter is on a class level.
        cls.counter += 1
        return super(ClassLevel, cls).__new__(cls)

i1 = InstanceLevel()
i2 = InstanceLevel()
print(i1.counter, i2.counter)  # 1, 1

c1 = ClassLevel()
c2 = ClassLevel()
print(c1.counter, c2.counter)  # 2, 2
```

As you can see, with the `InstanceLevel` example, each instance starts from 0 and as
we initiate it, it adds 1. So both instances get the value 1.

However, with `ClassLevel` it is counting and sharing the counter between both instances
which means that since we create 2 instances, both end up having the counter value 2.


## Difference between __new__ and __init__ in Python

The second question that you might have after seeing our implementation of a Singleton in
Python might be wha the difference between `__new__()` and `__init__()` is. They sound like
almost the same thing, and judging from our examples with the instance level vs class level
variables above, they look to do almost the same thing.

Well -- both of them relate to creating new instances of a class, but they have different purposes.

`__new__()` is called when we create a new instance of our class. When this function is called,
we do not have an instance yet, therefore we do not get the instance passed in as `self` in 
the function signature.

As you can see from our code, `__new__()` is not a void function, it must return the created
instance. You could think of `__new__()` as the default factory method or `@classmethod` of
our class.

`__init__()` on the other hand is called **after** our instance has been created. That is why
it can accept the instance itself as `self` in the function signature. It's job is not to create
the instance but simply act as a hook to **initiate** the instance's values.