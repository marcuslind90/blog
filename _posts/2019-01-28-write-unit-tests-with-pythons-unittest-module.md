---
layout: post
title: Write Unit Tests with Python's unittest Module
date: 2019-01-28 00:00:00 +0000
categories: docker
permalink: /@marcus/write-unit-tests-with-pythons-unittest-module
---

Writing great unit tests is one of the things that I've discovered throughout my career to have the single most impact on the quality of code that I produce as a software engineer.

Obviously, there are other things such as doing code reviews or working in great companies with talented coworkers, that has also inspired me to grow as a programmer, have more pride in the work I do, and to produce more stable and beautiful code. But none of those things has allowed me to grow with such a  direct impact as by doing proper unit testing.

By writing proper tests it does not only show that you care about the quality of the code that you're writing right at this moment, but it also shows that you have a long term perspective and care for the future of the project. Your tests both confirms that the code that you have written work properly, but it also gives the ability for future developers to refactor your code while still having confidence that it's keeping its desired functionality.

## Why should we write Unit Tests?
Unfortunately, unit tests are very often overlooked and deprioritized. Sometimes this is the fault of the programmer who simply doesn't care, but other times its the fault of the product owner or project leader, who keep putting tasks on the programmer's todo-list, and the programmer has to just churn out code as fast as possible, without being given the small amount of extra time required, to make sure that the code produced follow best practices, and will be easy to maintain for years to come.

There has been plenty of studies that have looked into the practice of test-driven development, to see if the extra amount of time spent writing tests has the desired outcome that makes up for it.

IBM and Microsoft made a study called "The Springer study" where they compared different teams way of working, and their approach to writing unit tests. The study showed that with only 20% extra work, the number of bugs was reduced by up to 90%.

> The Springer study showed 40% — 90% reduction in bug density relative to similar projects that did not use the test-driven development.

Those numbers should be enough to convince any project leader or product owner that they should give the programmers the extra time needed to keep their test coverage high.

## The Unit Test Module in Python
There are a few different testing libraries or modules out there that allow us python developers to write and run unit tests efficiently. Each one usually follows a similar pattern, but they might come with different tools or syntactic sugar that allow us to shorten the code needed to test our code.

Personally, I prefer using Python's built-in `unittest` module. It gives us all the tools we need to write proper unit tests. It's also used by web frameworks such as Django, so having a proper understanding of the built-in module will set you up to easily adopt future code bases built by other developers in python.

Let's write a simple example:

	::python
	from unittest import TestCase

	class FooTestCase(TestCase):
		def test_foo(self):
			self.assertTrue(1 + 1 == 2, "1+1 should be 2.")

Let's summarize what we're doing here:

- We import the `TestCase` class from the `unittest` module.
- We define our own `FooTestCase` which will hold all of our unit tests.
- We write a unit test prefixed with `test_` called `test_foo`. This test simply asserts that a simple math expression is true.

We can then run this from bash with a single command. If we saved the code above in a file called `main.py` we can call it in the following manner:

	::bash
	python -m unittest main

You will then see some output like this:

	::bash
	.
	-------------------------------------
	Ran 1 test in 0.000s

	OK

### What is a TestCase?
A "Test Case" is a collection of unit tests in Python that all test the same cluster of features. If you do object-oriented programming, it's pretty common to have a Test Case per Class in your code base.

For example, you might have a `Car` class and a `CarTestCase` class that holds the unit tests that is testing the `Car` functionality.

All Test Cases inherit from the base `unittest.TestCase` class. This class gives us all the features needed to run and to create our unit tests. As you could see in the example above, we created our `FooTestCase` by inheriting from `TestCase`, and then we used methods from `TestCase` such as `self.assertTrue()` to test the expressions of our unit test.

The `TestCase` class include much more tools and methods than this, a list of some of the most commonly used methods would be:

- setUp
- tearDown
- assertEqual
- assertTrue
- assertFalse
- assertRaises

#### Using the TestCase setUp and tearDown Methods
The `setUp()` and `tearDown()` methods of the `TestCase` class can be used to prepare data that will be used across many of your unit tests within your test case. This allows you to keep your code DRY and keep it cleaner and easier to understand.

For example, imagine that we have a TestCase for `Car` class. For us to instantiate a `Car` object, we might need to also create instances of `Wheel`, `Material`, `Color` and other things that the `Car` object depends on.

We have to do all of this preparation, just so that we can instantiate our object and run the test on it. On top of this, every single test method within our Test Case will probably need its own object of `Car` so we would have to repeat all of this initiation code over and over again.

Instead of doing this mess, we can simply define all of this within the `setUp()` method, and then reuse it within each `test_` method.

For example:

	::python
	from unittest import TestCase

	class CarTestCase(TestCase):
		def setUp(self):
	                material=Material()
			color = Color()
			wheel_type = WheelType()
			self.car = Car(
				material=material,
				color=color,
				wheel_type=wheel_type,
			)

		def test_foo(self):
			self.assertEqual(
				self.car.wheel_count, 
				4, 
				"A car should have 4 wheels."
			)

Note that the `setUp()` and `tearDown()` methods will be executed before and after each `test_` method. This means that if your test modifies the objects defined within the `setUp` method, the next `test_` method will still get a fresh instance. 

#### Why use TestCase assert methods instead of Python assert?
In the list of methods that `TestCase` gives us access to, you could see that it defines multiple different methods that start with `assert*`. For example `assertEqual` or `assertTrue`. 

If you're an experienced Python developer, you might also know that Python comes with the `assert` statement out of the box. You could, for example, write `assert 1 == 1` and it would raise an Exception if the statement wasn't true.

So why would we want to use `TestCase` assert methods instead of the one that already exists within Python? The main reason is that by using the methods defined within the test case, your test runner can automatically generate a report instead of just raising an exception when an `assert` statement fails.

Remember that output that I showed you above that returned the number of tests and how long they took to execute? All of that is possible because we take advantage of the features that `TestCase` offers us. Because of this -- Always use the built-in `self.assert*()` methods when you're writing unit tests within a `TestCase`.

### How to run Python Unit Tests?
You can run all of your unit tests with a single command.

	::bash
	python -m unittest

That will create a `TestRunner` that will try to execute all of your test cases and test methods. But how does the `unittest` module know which files to look for and which methods to execute?

The test runner expects you as a developer to follow certain standards or rules that will help it to properly discover which tests that it should execute. These rules are:

- All test methods within a test case should start with `test_`. 
- Your test files should follow the naming pattern `test*.py`.

By following those naming standards, the Python `unittest` module will automatically discover the tests for you recursively through the folder structure from where you run the command.

If you want to run a specific file instead of relying on the automatic discovery that will execute all your tests, you can provide a python path to the file that you want to test.

	::bash
	python -m unittest apps.foo.bar

That will limit the testing to the provided python module. This can be extremely useful if you're attempting to fix some tests in a specific module and you want to iterate quickly on your unit tests without having to run your complete test suite.

#### Test Runner Auto-Discovery
The Auto Discovery is the process of allowing the `TestRunner` to automatically attempt to discover all the unit tests within your code base.

The test runner automatically enables the discovery functionality whenever you call it without arguments (like in our example above in the previous section) but you can also explicitly use the Automatic Discovery in the following manner:

	::bash
	python -m unittest discover

That will allow you to also provide custom options and flags to the `discover` command such as `--pattern`, `--start-directory` or `--top-level-directory` to control how and where the automatic discovery will attempt to discover the tests.

## What is Mocking?
Imagine that we have a unit test that is responsible for testing the user registration feature of our application. Obviously, we want our test to make sure that a user can be registered, but do we really want the test to create a real user in our database each time we run it?

If we run our tests thousands of times, it would mean that our test would create a new user in our database for each and every time. That would not only be annoying to deal with from a data perspective, but it would also slow down our tests since it will be writing to the database all the time.

This is where the concept of Mocking enters the stage. A Mock is a fake, stub or a replacement of some existing object, variable or callable that return a pre-determined response.

For example, we might test the whole flow of our user registration, but we might mock the database adapter so that when it attempts to write it to the database, we fake it and return back that the INSERT query was successful, even though it was actually never even attempted.

Your first impression to this might be something along the lines of "Doesn't that mean that we didn't properly test our code?". Well, the thing is... Do we really need to test that the database adapter that we're using is working as expected? Or do we trust that the programmers of the database technology have properly tested things on their side?

We shouldn't test things that we trust and expect to have already been tested elsewhere. We should only test the code and features written by ourselves.

### The Unittest Mock Class
Technically, a "mock" could be any type of class that you replace another class with. For example, we might have a `DatabaseAdapter` class that is responsible for interacting with our database, and we might just create a `DatabaseAdapterMock` class that we use to override some of these methods and stop the connection to the database.

If we want to save ourselves a lot of typing though, we can just use the built-in `Mock` class that comes from the `unittest.mock` library. This class gives us a ton of features that save us from having to type things out ourselves.

Let's write an example:

	::python
	from unittest import TestCase
	from unittest.mock import Mock

	class FooTestCase(TestCase):
		def test_foo(self):
			db_mock = Mock()
			db_mock.execute.return_value = True
			res = foo(db=db_mock)
			self.assertTrue(res, "Result should be True")
	
	def foo(db):
		res = db.execute("INSERT INTO foo (name) VALUES ('bar');")
		if res:
			return True
		else:
			return False

In the example above, we are writing a unit test that tests our `foo()` method. As you can see the `foo()` method is attempting to write something to the database, which we don't want to happen during our unit test.

To solve this, we define a `db_mock` variable that we pass into the `foo()` method. Because we use the `Mock` class, we don't even have to define a `execute()` method, instead, all we have to do is set the `execute.return_value` property on our `Mock` object to return the expected value.

### Mock by Patching
In the example above, we were quite fortunate because the `foo()` method was exposing its `db` adapter through a keyword argument in the method signature. This allowed us to very easily pass in a replacement mock that we wanted to use for the unit test.

But what if this is not always the case? For example, let's say we want to mock the built in `open()` function that read files, or maybe we want to mock an imported class or function.

This is where "Patching" comes in. By using patching, we can create an isolated context where the patched variable is replaced with our mock wherever it's being used. This means that we don't have to have any direct access to it for us to be able to replace it with a mock.

Let's rewrite our previous example into a version that doesn't expose the database adapter in the method signature, and then lets mock it using Patch.

	::python
	# File test.py
	from unittest import TestCase
	from unittest.mock import patch, Mock
	

	class FooTestCase(TestCase):
		@patch("app.db")
		def test_foo(self, db_mock: Mock):
			db_mock.execute.return_value = True
			res = foo()
			self.assertTrue(res, "Result should be True")
	
	# File app.py
	from customdb import db

	def foo():
		res = db.execute("INSERT INTO foo (name) VALUES ('bar');")
		if res:
			return True
		else:
			return False

As you can see, by using the `@patch` decorator, we can get a mock instance of the `db` instance used within `app` and then pass it into our test, so that we can set the expected mock values. This is extremely powerful and it means that unlike some other languages where you *must use dependency injection* to be able to write proper unit tests, with the Python `unittest` module, we can simply reach into our code and mock objects without necessarily exposing them through method signatures.

Note that when we define the `@patch` path to the object we want to mock, we don't write the path to where its defined (`customdb.db`) instead, we write the path to where it is being used within our code (`app.db`).

### Assert a methods actions instead of its return value
So far in this article, we have learned how to test the response of a method. But what if we don't want to test that a method returns something, but instead we want to test that a method DOES something?

For example, let's say that we have the `foo()` method in our example above, but instead of returning True or False based on if it was successful or not, all we want to do is to test that the `db.execute()` method was called once.
 
	::python
	# File test.py
	from unittest import TestCase
	from unittest.mock import patch, Mock
    

	class FooTestCase(TestCase):
		@patch("app.db")
		def test_foo(self, db_mock: Mock):
			foo()
        	db_mock.execute.assert_called_once()

    
	# File app.py
	from customdb import db

	def foo():
		db.execute("INSERT INTO foo (name) VALUES ('bar');")

As you can see, the `db_mock` variable which is of type `Mock` can use methods such as `.assert_called_once()` on any of its attributes, properties or methods to create an assert that checks if the callable was called in some specific manner.

By doing this, we can test the behavior of our `foo()` method without it returning anything. This is incredibly useful and its something that you will run into over and over again.

On top of asserting how many times something was called, you can even assert that a callable was called with certain arguments using `.assert_called_with()`.
