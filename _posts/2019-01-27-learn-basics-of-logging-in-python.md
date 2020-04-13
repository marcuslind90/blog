---
layout: post
title: Learn Basics of Logging in Python
date: 2019-01-27 00:00:00 +0000
categories: docker
permalink: /@marcus/learn-basics-of-logging-in-python/
---

The Python logging module is in the core of things that you need to learn to master the Python programming language. By using logging extensively throughout your program, you will not only massively improve your ability to debug reported errors, but you'll also get great insights into how your users are interacting with your application.

Unfortunately, even though logging should be part of any program, it is often overlooked by lazy, and naive programmers who focus more on the quantity of code they can write instead of the quality of it. By making sure that you follow best practices and write high-quality code, you'll be a favorite member of any team, and be a joy to work with. Because of this, you should put some effort into properly understanding the logging module in Python.

## When and Why Should We Use Logging?
Have you ever received an email from a product owner, a co-worker or in the worst case, a visitor, who inform you of some error that they just discovered in the application that you created?

If you're lucky they might give you screenshots of the error message, which URL Path they encountered the message on and information of how you can reproduce it. However, more often than not all you will hear is "I got some error yesterday at noon somewhere on the application". Where do you even start with debugging something like that?!

Was there even a real error that occurred or was it a client issue?

By making sure that you properly log what goes on in your application, all of these things will be a breeze to solve and work out. Even when you don't get the detailed information that you might require, a time stamp of when the error occurred is often enough to find additional clues that will help you solve it, and improve the quality of your application.

I've worked as a professional software engineer for 10+ years, and every single role or company that I've worked in, debugging has been one of the core things that has been part of my daily tasks. Why wouldn't we want to spend a few minutes of our time to make sure that our code implements logging, so that whenever we come back to it for debugging, we can easily lock down the error?

## How to use Logging
The `logging` module in Python is a core module in the language. It is always available and you don't need to install it from any remote package repository. You simply import it, and its ready to be used.

```python
import logging
```

To understand how logging works and how to configure it, we have to understand a few key pieces.

- Loggers
- LogRecords
- Formatters
- Handlers
- Filters

### Loggers
A Python `Logger` is the object that is responsible for creating log entries. It is your main way of interacting with the logging module within your code.

A `Logger` has a name, and a code base can contain many different loggers. For example, imagine that we have the following modules in our code base:

```bash
./
    apps/
        foo/
            app.py
        bar/
            app.py
    main.py
```

In this case, let's say that each `app.py` file within our code base has their own `Logger` defined. Each Logger might be named with the path to the file. For example `apps.foo.app`, `apps.bar.app`.

By naming our loggers like this, we can later target the configuration to a specific logger, or all loggers within a group. For example, we can configure the log output of `apps.*` which would include both the output of `apps.foo.app` and `apps.bar.app`

This naming convention is the standard way to name your loggers, and its usually done by using the `__name__` variable in python when we initiate our Logger. It will then automatically pick up the execution path of your file as the name of the Logger.

```python
import logging
logger = logging.getLogger(__name__)
```

### LogRecords
A `LogRecord` is just the object that represents each log message/entry/record (All of it is common terminology for the same thing). It holds the information about the log entry such as its Time, Message, Level and other metadata about the log record.

The `LogRecord` by itself does not take any consideration into how the final log message should be formatted or how it should be stored. All it does is hold the information that relates to the log entry.

When you write something like the following:

```python
logger.debug("This is a debug message")
```

What you actually do is that you create a `LogRecord` for the Logger.

### Formatters
Formatters are what determines how each log message gets formatted and represented within your final log. Remember that in the example above, all we wrote as a message was "This is a debug message"? What if we also want to include information such as the Timestamp, Module, Log Level and more into each text entry?

We don't need to manually do that to the log message itself, remember that `LogRecord` already hold a lot of metadata for us? By using a `Formatter` we can format the `LogRecord` into a single line of text, that is the final result that gets stored or outputted in our log.

We could create a `Formatter` in the following way:

```python
import logging

formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# logger.debug("This is a debug message")
# 2019-01-27 18:01:18,771 - __main__ - DEBUG - This is a debug message
```

One great thing about Formatters is that you can also define different formatters to be used by different Handlers. You could output a more minified version of your `LogRecord` to Handler A, while you include additional metadata to Handler B. 

### Handlers
A `Handler` is the object that determines how your log entries are stored or which channels they are output to. You could have a `FileHandler` that store the log records to a `.log` file, or you could have a `MailHandler` that sends the log records to someone's email. 

There are plenty of different handlers by default and it includes:

- StreamHandler
- FileHandler
- SMTPHandler
- SocketHandler

The most commonly used handlers are the `StreamHandler` which outputs the log output to `stdout`/console/terminal, and the `FileHandler` that store the output to a log file on the system.

A logger can output its data to multiple handlers, and each handler can have its own configuration such as its own Formatter and its own Log Level.

This means that you could set up a `StreamHandler` for all DEBUG messages while also setting up a `SMTPHandler` for ERROR messages so that an administrator receives an email when a serious or critical error occurs.

### Filters
Finally, we have Filters. A Filter is basically a callable that you connect to a `Handler` or `Logger` that determines if the log record should be included or not.

You can imagine that the Log Level is kind of a filter. You set that a Logger should only store messages that are of a certain Log Level or above, and this is exactly how Filters work. You can create a Formatter that determine if an object should be included based on many different parameters.

## How to Write Log Messages?
So let's write our first log entry using our newly instantiated logger. This is done with methods on the logger that match the Log Level of the entry we want to create.

What are Log Levels? In python, there are 5 different levels that determine the severity of the message.

- DEBUG
- INFO
- WARNING
- ERROR
- CRITICAL

Each level indicates if the error message is simply just "Debugging information", "Information of an event" or "An error that occurred".  You as the developer are responsible for making sure that messages are logged in the appropriate level. 

You write log messages for each level in the following way:

```python
import logging

logger = logging.getLogger(__name__)

logger.debug("This is a debug message.")
logger.info("This is an info message.")
logger.warning("This is a warning message.")
logger.error("This is an error message.")
logger.critical("This is a critical error message.")
```

Each log message will automatically be stored in its correct level based on the method used whenever you log the message. But where will the Log Records be output in the example above? And which format will each log entry use?

To determine all of these things, we have to configure our logger.

## Configure Python Logging
There are 4 main ways to configure our the logging behavior of our application. 

- Use basicConfig.
- Explicitly create classes and connect them together.
- Use a dictConfig to store configuration as a Python Dictionary.
- Use a fileConfig to store the configuration as a file.

The most commonly used method to configure logging is to use the `dictConfig`. This is also the recommended method that you will see from the Documentation of frameworks such as Django or Flask.

### Use BasicConfig
To quickly get going with logging you can simply use the `logging.basicConfig` method. By doing that you can simply define your settings with a single line of code.

```python
import logging


logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

logger = logging.getLogger(__name__)
logger.debug("Hello World!")
```

Here we just define a `format` kwarg of our config and we are now ready to output our log records with a `StreamHandler` to the terminal. Note that the configuration is set on the `logging` level, and it will be set globally throughout our whole app.

This means that if we have an imported method that live in another module or package that also has log statements in it, those log statements will also be affected by the `basicConfig` defined.

### Explicitly Define Handler and Formatter Classes
Instead of providing a configuration that will be used for all loggers, we could also manually create `Formatter` and `Handler` objects that we then connect to our `Logger` instance. 

This is not really recommended and its rarely used, but it allows us to see how things are connected between each other.

```python
import logging


logger = logging.getLogger(__name__)

# Create handler
handler = logging.StreamHandler()

# Create formatter and add it to handler
format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(format)

# Add handler to the logger
logger.addHandler(handler)

logger.debug('This is a debug')
```

These assignments will not be reused by other loggers that might be part of other files within our code base. Because of this, it's not a very "DRY" method of configuring our `Logger` and it's therefor not recommended.

### Use dictConfig to Configure Logging
The most popular method to define the logging configuration is to do so in a Python Dictionary and then pass it to the `logging.config.dictConfig(config)` method.

Not only does this make things very explicit and clear, but it's also DRY and it only requires you to set this at a single location within your code, while you're bootstrapping your application. 

Here's an example of how you can provide a dictionary as a config for your python logging module.

```python
import logging
import logging.config

logging.config.dictConfig({
    'version': 1,
    'formatters': {
        'minimum': {
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        }
    },
    'handlers': {
        'stream': {
            'class': 'logging.StreamHandler',
            'formatter': 'minimum',
            'level': 'DEBUG',
        }
    },
    'loggers': {
        'apps': {
            'handlers': ['stream', ],
            'level': 'DEBUG',
            'propagate': True,
        }
    }
})
logger = logging.getLogger(__name__)

logger.debug('This is a debug')
```

Let's summarize what we're doing here with this config:

- We create a `Formatter` called `minimum` that we add a format to which will output the log entries as `<time> - <module name> - <log level> - <log message>`.
- We create a `Handler` that is called `stream` and that use the `StreamHandler` which will output all of our log messages to the console. We tell it to use the `minimum` formatter that we already defined and that it should include `DEBUG` Log Levels and above.
- We create a `apps` logger that use the `stream` handler that we previously defined. By naming the key of the logger `apps` it will include ALL loggers that are a subname of `apps`. For example `apps.foo` or `apps.bar`.

Just like the `basicConfig`. When defining the configuration like this, it has a global effect. No matter if the log statements are in the same module where this configuration was set, or in a completely different module that is called later on in the execution, all of the loggers will use this configuration.
