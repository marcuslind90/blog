---
layout: post
title: Deep Dive Guide Into Python Type Hints and Type Checks
date: 2019-01-30 00:00:00 +0000
categories: docker
permalink: /@marcus/deep-dive-guide-into-python-type-hints-and-type-checks/
---

In 2012 a Finnish Ph.D. student from Cambridge named Jukka Lehtosalo approached the author of Python Guido van Rossum at a PyCon event regarding a new programming language named [Alore](http://www.alorelang.org/) that he had created which was heavily inspired by Python, but with the addition that it also supported optional type annotations.

Alore allowed you to write code with types, and then it used a transpiler to turn the code into pure Python. This pattern is popular and we can see it being used with [TypeScript](https://www.typescriptlang.org/) for Javascript Type Annotations.

This pattern allows software engineers to use types during the development of the product, while still allowing them to run the final production code using the Python/Javascript language.

Guido was impressed by the work that Jukka had done, but he didn't like the idea of a transpiler that converts code from one format to another, instead, he pointed Jukka in the direction of creating a tool that would work with pure Python, instead of creating a separate language.

This is where [mypy](http://www.mypy-lang.org/) and [PEP-484](https://www.python.org/dev/peps/pep-0484/) was born. Since then Jukka and Guido have been working on adding optional type hints into the Python programming language and since Python 3.6 it's now completely supported and available for anyone to use straight out of the box.

## Why People Love Duck Typing and Flexibility in Python?
A lot of people love the flexibility that languages such as Javascript or Python give them and the way that these languages allow developers to use generic variables without really caring what types they are in runtime.

For example, imagine the following method in Python:

	::python
	def calculate(a, b):
		return a*b

What type of objects is `a` and `b`? Does it matter? Python doesn't care as long as both of them have the `__mul__`  magic method defined, which is the magic method that determines how class handle multiplication. They could be a `float` and an `int`, it could be a `str` and an `int`, it could be 2 `float` or 2 `int` or any other combination of types.

The same thing goes for something like this:

	::python
	def save(file, content):
		file.write(content)

What type is `file`? We don't care, as long as it has a `write()` method defined within it, it will work fine. It could be an `IO` object that writes to an actual file, it could just be a class that writes it to a database, or just adds it to memory. Python doesn't care.

This concept is called "Duck Typing" and the "duck" part of the term comes from the following concept.

> "If it walks like a duck and it quacks like a duck, then it must be a duck"

Unlike other languages where the suitability of objects are determined by its type, in Python, the suitability of ability for an object to do something is determined by the properties and methods that the object has. This is also why it's so easy to monkey patch and Mock things in Python, all you have to do is to define an object that "behave" the same as the original object you're trying to mock.

This is one of the features that make the community love working with Python, and it's something that greatly simplifies learning the language and to speed up development of applications. But is it perfect? Or does it also come with some downsides?

## What's so Great About Type Hints?
Perhaps one of the most liked features about Python is how easy it is to read and understand code written in it. It's often clear, short and concise without being **too short** that it makes things confusing.

With that in mind, let's look at another code example written in Python where once again, we don't define any Types in our function definition.

	::python
	from functools import reduce


	def get_total(items, rate):
		return reduce(
			lambda a, b: a+b,
			[item.total*rate.value for item in items],
			0
		)

What does this function actually do? Well, we know that it gets the total of something, but the total of what? If you were a programmer that worked on the project where this code is written, would you feel confident to reuse this function for your own purposes? Probably not.

This is where Type Hints can be so incredibly useful. Let's rewrite our method using the Python's Type Hints to see if we can improve the readability.

	::python
	from functools import reduce
	from typing import List
	from .models import Product, Discount
	

	def get_total(items: List[Product], rate: Discount) -> int:
		return reduce(
			lambda a, b: a+b,
			[item.total*rate.value for item in items],
			0
		)

The same amount of lines of code, but now suddenly things got much more clear. So our `items` are actually product items of the `Product` class, and the rate represents a discount rate of the `Discount` class. On top of this, we found out that we can always except the function to return an integer value.

The interesting thing about this though, is that all of these type annotations are completely ignored during runtime. Python still doesn't care about types, and it still uses Duck Typing. The only benefits we get from adding type hints or type annotations to our code is that we as developers can more easily understand it. We can also use Static Analysis such as Type Checkers within our IDE's or during our Continous Integration Pipeline, to make sure that methods are not misused within our code.

In the end, we can get the best of two worlds. The benefits of type hinting our code are:

- We get rid of any bugs that are of the kind where we misuse methods or functions by passing them incorrect arguments or types. This is an incredibly cheap way to increase the stability of our code base.
- We improve the readability of our code. Programmers that come along to our project will more easily be able to understand what a method does, and how to reuse it.
- We always get autocomplete features within our IDE. Our editor knows what objects that are passed into our methods. This greatly speeds up development speed.

### Python Uses Gradual Typing
Because Python doesn't care about types at runtime, it means that the type checking is completely optional and it's not binary in the sense of either you use it or you don't. You're allowed to gradually add type annotations wherever you feel like it, and there are no strict rules about how or when you should use them.

For example, if we wanted to, we could simply just annotate the first argument of our function and leave all the other ones as they are. 

	::python
	def get_total(items: List[Product], rate):
		...

The great thing about this is that if you have an old legacy code base that you want to add type checks to, you could do so gradually. You could start with a single library or even a single method within your code base and at least you know that you improved the readability of that specific piece by a little bit.

Dropbox, the company where Guido and Jukka work at have at this point in time added type checks to 2M out of 6M lines of code. It means that 66% of their code base still goes without type checks, and that's fine. That's one of the strong benefits of mypy and Python Type Hints, it's all optional and all of it can be implemented gradually.

## The Python typing Library
To get started with type hints in Python, you could just do so with the existing atomic types that you already know of such as `str`, `int`, `bool`, `float`, `bytes` etc. 

For example:

	::python
	def is_valid_path(path: str) -> bool:
		return True

But what about other more advanced types? For example, let's say you want to annotate an argument which is a list of items. You could simply use the `var: list` annotation, but that doesn't really give us the full picture does it? What type of items is the list made up of?

What we really want to know is if its a list of `int`, `str` or any other type, so that when we iterate over the list we know what we can expect it to contain. This can't be done with the atomic `list` type and we need something else to help us out.

This is where the [Python Typing Library](https://docs.python.org/3/library/typing.html) comes into the picture. The `typing` module contains a lot of custom types that we can use to give a more detailed image of what type our objects or variable are.

For example, we could use the `typing.List` type to give us the ability to not just type hint that an argument is a list, but also what type of objects our list contains. 

	::python
	def words_to_ord(words: List[str]) -> List[int]:
		return [ord(word) for word in words]

Some of the other types that the library contains that helps us give a better and more detailed image of our variables are:

- `Dict`
- `Set`
- `Tuple`
- `Generator`
- `Callable`
- `Iterable`
- `Type`
- `Any`

Some of these types are "Container Types" which basically allow us to define what the type contains. For example with the `List` we can write `List[int]` to show that its a list of integers, or with `Dict` we can write `Dict[str, Any]` to show that the keys are made up of `str` and the contents could be `Any`.

### What is the Python typing.Any type?
The `Any` type is a special type that will match any object. This means that the following two points are always true:

- Every type is compatible with Any.
- Any is compatible with every type.

This is unlike `object` where it's true that every type is an `object`, but `object` is not every type. 

For example:

	::python
	# Valid
	def foo(item: Any):
		item.write("Hello World")
	
	# Invalid
	def bar(item: object):
		item.write("Hello World")

It's true that any item we pass in is an `object`, but that does not mean that `object` has a `write()` method.

## How to Run Python Type Checks
There are actually multiple type checkers that has been created for Python. 
The most popular one and the one that Python's author Guido and Jukka are working on is [mypy](http://www.mypy-lang.org/).

You can run mypy by itself, but it's also integrated into linters such as `flake8` and can be added by installing the `flake8-mypy` extension.

Other Type Checkers that have been created are:
- [pytype by Google](https://github.com/google/pytype)
- [pyre-check by Facebook](https://github.com/facebook/pyre-check)
- [pylint](https://www.pylint.org/)
- PyCharm Custom Type Checker

My own personal choice is to use `mypy` with `flake8`. It does not only give me the ability to do static analysis of my type hints, but it also allows me to lint my code and shows any style errors that might have been introduced. It covers all my needs when it comes to maintaining a clean code base.

	::bash
	pip install flake8 flake8-mypy
	flake8 .

## Type Annotation Syntax
The core part of type hints in Python is to annotate your variables, arguments or methods with Type Annotations. The base syntax for this is to use the `:` character followed by the type. E.g. `foo: str = "Hello World"`.

You can add type hints to both function arguments, function return types and variable definitions. Let's go through them all together.

### Function Annotation
One of the most common places to add type annotations to will be the functions in your code. You can both add type hints to the arguments, but also to the return type of the function.

	::python
	from typing import List


	def reverse(words: List[str]) -> List[str]:
		return words[::-1]

As you can see, in the example above we annotate our `words` function parameter to be a list of strings. We also add an annotation of our return type using the `->` arrow syntax to hint that our method also returns a list of strings.

As I mentioned in previous sections of this article, Python uses gradual typing which means that all of this is optional. We could leave out the annotation of the return type if we wanted to, and only keep the type hint of the function argument.

#### Type Hint None or Void Return Types
Many other programming languages have the concept of void methods. Void methods are methods that don't return anything at all like the following example.

	::python
	def save(file):
		file.save()

All our `save()` method does is that it executes an action. It doesn't return any value back to the caller, so this is what we could call a `void` method in general programming terminology. So how do we hint this in Python? We use the `None` type.

	::python
	def save(file) -> None:
		file.save()

Obviously assigning the return value of this function to a variable wouldn't make sense, because it doesn't return anything. Without type hints, we would not automatically discover this, but writing something like `res = save(f)` would now give us an error and inform us that the function doesn't have any return value.

#### Type Hint Optional Arguments
If you annotate an argument with a type, it means that we will always expect that argument to be set to that type. But what if we want to have an optional argument that sometimes is set to that type, but in other cases is `None`?

The `typing` library offers us a great tool that will help us out with this in the form of the `Optional` type. We can use this to both indicate that a function argument can be optionally set, but we can also use it to indicate that the return type of the function is optional.

For example:

	::python
	from typing import Optional
	from .models import User


	def foo(path: str, user: Optional[User] = None) -> Optional[int]:
		# Do something...
		...
		if user:
			return user.id
		else:
			return None

In the example above we use type annotations to hint that the `path` argument is always set to a `str` type, while the `user` argument is sometimes set to a `User` type but other times it might be set to `None`.

As we see from the execution of our function, the return type is also dependent on the input to the argument. Sometimes we return a user ID in the form of an `int`, while in other times we return `None`. 

We are able to hint the return type about this behavior by using the `Optional` type.

### Variable Annotation
Functions are not the only case where it can be useful to use type hints. We might also want to use it with normal variables. This can be achieved using the same syntax.

With variable type hints, we can choose if we want to annotate the variables separately from the assignment, or at the same time. For example, in the code block below we are assigning `self.id` and `self.username` on multiple different locations, it might be cleaner to just type hint them a single time instead of having to repeat it everywhere they can be assigned.

	::python
	class User(object):
		id: int
		username: str

		def register(self, username: str) -> None:
			self.id = self.get_latest_id()
			self.username = username
		
		def get_existing(self, user) -> None:
			self.id = user.id
			self.username = user.username

However, we can also combine the type annotation with the assignment in the following manner:

	::python
	username: str = "weeman"

### Comment Annotation
The syntax and tools required to add type hints to arguments, variables or function return values were added during Python 3.5 and Python 3.6. But what if you want to add type hints to older Python code?

The type checker `mypy` is a program written in Python 3, but all it does is that it analyzes text files, so why wouldn't it be able to analyze text files written in, for example, Python 2.7? This is possible!

Unfortunately, you can't use the `:` or the `->` syntax. Instead, you have to annotate your code using comments. 

	::python
	def calculate(a, b, c):
		# type: (int, int, int) -> int
		return a+b*c

That `# type: ` comment would then tell our type checker that the `calculate()` method has 3 arguments of type `int` and it also returns an `int` value.

This can be incredibly useful if you're working on a legacy code base or if you are working on modules or libraries that need to be available in previous versions of Python. However, if you're working on Python3.6+ I would strongly recommend you to use the standard syntax since it's much cleaner and more readable.

## Type Aliases
Sometimes we might have some really complicated types. For example, imagine that we pass in a list of connection parameters to our method.

	::python
	def connect(connections) -> None:
		...

	connect(connections=[
		(
			("psql://", "hostname.com", 5432, ),
			("username", "password", ),
		), 
		(
			("http://", "hostname.com", 80, ),
			("username", "password", ),
		),  
	])

We would then have to annotate our `connect()` function in the following manner:

	::python
	from typing import List, Tuple

	def connect(connections: List[Tuple[Tuple[str, str, int], Tuple[str, str]]]):
		...

Ouch right? For these situations, Python offers us something called "Type Aliases". A Type alias is basically just a reference to a type definition. We could then rewrite our `connect()` type annotations to the following.

	::python
	from typing import List, Tuple
	Host = Tuple[str, str, int]
	Credentials = Tuple[str, str]
	Connection = Tuple[Host, Credentials]

	def connect(connections: List[Connection]):
		...

That small change greatly improved the readability, while still giving us the full power of type hints and checks for our method.

## Conclusion
Type Hints, Checks, and Annotations are something that is incredibly useful in Python and it's here to stay. In the upcoming years, I am positive that the practice of type hinting your code will become more widespread within the Python community and as a software engineer, you will be expected to have a good grasp of it.

It's very easy to get going with it because of the gradual typing concept that allows us to start small and iterate over and over until we get greater coverage with our annotations. 

This means that no matter if you're starting off with a new project, or if you're working on a legacy code base, type hints are for you.
