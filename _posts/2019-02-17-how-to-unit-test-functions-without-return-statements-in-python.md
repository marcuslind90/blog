---
layout: post
title: How to Unit Test Functions Without Return Statements in Python
date: 2019-02-17 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-unit-test-functions-without-return-statements-in-python
---

Unit Testing is one of the core concepts within programming that any software engineer should have a proper understanding of. Normally, we usually test and assert that a method returns a certain response, but what about functions that don't return any response? How do we test and assert that they do what we intend them to do?

By using mocks, we can assert that given objects behave in expected ways. We can assert many different things such as:

- How many times a callable within our tested function was called.
- Which arguments that were passed into any callable within our tested function.
- What response a callable within our tested function returned.'

This means that even though our functions do not return any response, we can still test and assert that objects or callables within our tested function behave in certain ways, and in that manner make sure that our code works as expected.

## Examples of Common Situations

Let's start off with a few examples to illustrate the problem at hand. Let's say that we have the following methods and we want to write a unittests for each one.

```python
def save_data(data) -> None:
    if 'foo' not in data:
        raise KeyError("foo field is not set in our data dictionary.")

    instance = MyModel(**data)
    instance.save()
```

How would we write a unit test that makes sure that the `instance.save()` method is called given a certain input?

```python
def update_status(url, data) -> None:
    status_code = data.get("status")
    if status_code == 0:
        status = "FAILED"
    elif status_code == 1:
        status = "SUCCESS"
    else:
        raise ValueError("status_code must be 0 or 1.")
    
    http_client.put(url, dict(status=status))
```

How do we write a unit test that makes sure that we send "SUCCESS" to the `http_client.put()` method given a certain input?

```python
def delete_items(items) -> None:
    # Filter out items
    items = [item for item in items if item.status == "DONE"]

    for item in items:
        Model.delete(item.pk)
```

How do we write a unit test that makes sure that `Model.delete()` was called the correct amount of times given a certain input?

All of the code examples above illustrate examples of functions without a response, that still need to be tested in different ways. This is very common situations that you will encounter over and over again as you write unit tests to make sure that your code is working correctly. Unfortunately, it's fairly common to see programmers skip writing tests for these type of functions because it is "too complicated". It's easier to just use `self.assertTrue()` or `self.assertEqual()` to simply make sure that a function returned an expected response. It's more difficult to test the actual behavior within the functions.

## Using Mocks to Stub, Replace and Test Objects

Python gives us all the tools that we need to write proper unit tests, you should already be familiar with the `unittest` module that is included in the core python installation, but now we will also use the `unittest.mock` module, which gives us access to additional tools needed for these test cases.

The main part of Python's mock module is the `Mock` class. Other functions, decorators and classes within the module is either about how to create `Mock` objects in clever ways or are subclasses that inherit from `Mock`. If you properly understand the `Mock` class, it will be easy to understand the rest of the `unittest.mock` module.

So what is a Mock? A mock is a fake, stub or replacement of a class or object. It's an object that has all properties and methods that you try to call on it, and it will always return a successful response. The trick is that it also keeps track on all methods called on it so that you can later assert the behavior done to your mocked object during your test.

For example, all of these calls are valid on a Mock.

```python
from unittest.mock import Mock

Mock().hello_world()
Mock().whatsup()
Mock().foobar()
Mock().foo().bar().hello
```

So what do each method return if we never defined the method anywhere? Well, this is the genius thing, each method on our `Mock` object return new `Mock` objects. It's like an infinitely deep traversal of mocks. It's genius.

Are you confused? Well let's say that we have a simple method like this:

```python
def write_to_db(db_connector, query):
    db_connector.execute(query)
```

We don't want it to actually write things to the database. We can, therefore, write a unit test that looks something like this:

```python
from unittest.mock import Mock

def test_write_to_db(self):
    db_connector = Mock()
    write_to_db(db_connector, "MY QUERY")
```

The object we pass in is no longer a real "database connector", but it can still execute the `.execute()` method, so our code is still valid and will still execute correctly. I hope this gives you a proper understanding of why the `Mock` object is useful, and how it can be used.

### Use the Patch Decorator to Create Mocks

In the example above, we could simply pass in the `db_connector` Mock as an argument to our function. Unfortunately, in reality, it's not always this easy. Often items or functions are imported or instantiated within the function we're testing, not just passed in. How do we create a `Mock` if we cannot pass it into our function? The answer is to use the `unittest.mock.patch` decorator.

By using `@patch`, we actually create a context manager that wraps our called function and then replace any use of an object with a `Mock`. This is awesome! What this means is that we can replace instances of objects that are defined within our code, and not passed into it.

For example, let's look at a slightly modified version of our previous example.

```python
from utils import DBConnection


def write_to_db(query):
    db_connector = DBConnection()
    db_connector.execute(query)
```

As you can see, we can no longer pass in a `Mock` version of our database connection. Instead, we have to replace it inside our function using the `@patch` decorator.

```python
from unittest.mock import patch


@patch("path.to.our.file.DBConnection")
def test_write_to_db(self, db_connection):
    write_to_db("MY QUERY")
```

This replaces the `DBConnection` class in the context of our unit test, with a `Mock` object. What this means is that anywhere that `DBConnection` is used, it will now be replaced by a mocked instance. This `Mock` object is then passed into our unittest from the `@patch` decorator, and we can access it and modify it in any way we want within the unit test itself.

These two methods of creating `Mock` objects will be enough to cover most of the scenarios that you will run into while writing unit tests for Python code.


## How to Assert That Function Was Called?

So, by using mocked objects as replacements for the objects within our code that we want to test, how do we assert that a certain method on a given mocked object has been called? 

Let's take a look at one of our examples from before.

```python
def save_data(data) -> None:
    if 'foo' not in data:
        raise KeyError("foo field is not set in our data dictionary.")

    instance = MyModel(**data)
    instance.save()
```

How do we test that the `instance.save()` method is being called?

```python
@patch("path.to.code.MyModel")
def test_save_data(self, model_mock):
    save_data(data=dict(foo="Hello World"))
    # Assert that the save method on our mock
    # object has been called exactly 1 time.
    model_mock.save.assert_called_once()
```

Remember, our `@patch` decorator creates a context manager around the unit test where any usage of `MyModel` gets replaced with a Mocked object, which instance is passed into our unit test as an argument. When we call `save_data()`, we execute our method and `.save()` is called on our mocked object, instead of the real `MyModel`. After the execution of our method, we can then assert that the method was called.

The `Mock` class keeps count on how many times a method has been called, this means that our assert also makes sure that it has been called exactly one time. If you would call `.save()` twice, the assertion would raise an exception and the unit test would fail as expected.

Here we illustrated how we can test a method without a return statement. Even though the method doesn't return any response, we can still reach into the method and test the logic that is being executed inside.

## How to Assert Which Arguments That Was Passed to Function

The next example that we had at the beginning of this article is the following.

```python
def update_status(url, data) -> None:
    status_code = data.get("status")
    if status_code == 0:
        status = "FAILED"
    elif status_code == 1:
        status = "SUCCESS"
    else:
        raise ValueError("status_code must be 0 or 1.")
    
    http_client.put(url, dict(status=status))
```

Unlike the previous example, we do not only want to test if the `.put()` method was being called, but we also want to test which arguments that was passed into it. Did it pass the status "SUCCESS" or the status "FAILED"?

We can once again do this by using the `@patch` decorator and create a mock object of our `http_client`, and then assert how that mocked object was being used.

```python
@patch("path.to.code.http_client")
def test_update_status(self, http_client_mock):
    update_status(url="http://myurl", data=dict(status=0))

    # Unpack the args passed into the put method when called.
    url, data = http_client_mock.put.call_args_list

    self.assertEqual(
        data['status'],
        "FAILED",
        "Status 0 should pass in FAILED",
    )
```

In the unit test written above, you can see that we are able to reach into the `.put()` call and get a list of each argument that was passed into the call by accessing the `call_args_list` property. By doing this, we can then use the standard `TestCase.assertEqual()` method to assert that the passed in argument is the expected value.

Note that if you called the mocked method multiple times, you can loop over `call_args_list` to get the arguments of the exact call that you want.

## How to Assert Number of Method Calls

The final example of common situations that we might run into when we are writing unit tests for methods that don't return any response, will be to assert the number of times something happened. Let's take a look at our example again.

```python
def delete_items(items) -> None:
    # Filter out items
    items = [item for item in items if item.status == "DONE"]

    for item in items:
        Model.delete(item.pk)
```

In this case, we might pass in 3 items, but because we filter the items we might only expect 2 of them to be deleted. This means that we want to write a unit test that asserts how many times the `Model.delete()` method was called.

Once again, we can use `Mock` objects as items that we pass into our method, and then assert if each item was called.

```python
patch("path.to.code.Model")
def test_delete_items(self, model_mock):
    items = [
        Mock(status="DONE"),
        Mock(status="DONE"),
        Mock(status="PENDING")
    ]

    delete_items(items)

    # Since only 2 items were status DONE, only 2
    # items should be deleted.
    self.assertEqual(
        len(model_mock.delete.call_args_list),
        2,
    )
```

Remember that the `call_args_list` property returns a list of arguments for each time a function was being called? That means that we can also count the number of calls by getting the length of the list. In the example above, we know that we only want our delete method to be called twice. We can then count the calls and assert that it is executed twice using the `assertEqual()` method.


## Summary of Unit Testing Methods Without Response

Ignoring writing unit test because they are "too difficult" to write is a bad excuse and it leads to bad practice. In reality, there are often very simple ways that you can achieve what you want if you just know the tools that are available to you. This is the tricky part, learning the tools. 

In this article, I have illustrated how you use `Mock` objects to reach into your code and assert how your code is being executed, even though your code doesn't return any response back that we can assert. I'm sure that you can think of many other cases of how these methods of testing can be applied.
