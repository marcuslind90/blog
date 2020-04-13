---
layout: post
title: Deep Dive into Python Mixins and Multiple Inheritance
date: 2019-02-07 00:00:00 +0000
categories: docker
permalink: /@marcus/deep-dive-into-python-mixins-and-multiple-inheritance/
---

In my opinion, Mixins is one of the most powerful, and useful features introduced in object-oriented python programming. It allows you to compose your classes in unique and reusable ways that simplify your code and in turn also helps you avoid repeating yourself when programming.

So what is Mixins? If you come from another language you might already have seen inheritance or even multiple inheritance, but Mixins are probably a new term for you if you're reading this article. What makes Mixins unique?

To be clear, Mixins in Python is just semantics. It's not a "thing" by itself, its just classes and normal inheritance. But it's when inheritance is done in a specific way. So in that manner, then you could say that Yes -- Mixins are the "same thing" as multiple inheritance. But let's explore it further than that.

## Mixins Cannot Be Intantiated By Themselves
Mixins are small classes that focus on providing a small set of specific features that you can later combine with code that live in other classes. This means that a mixin is always expected to be used together with other code that it will enhance or customize, a mixin is not intended to be used by itself.

For example, we could have a Mixin that looks like this:

	::python
	class MetaMixin(object):
		"""Mixin to enhance web view with meta data"""
		def get_meta_title(self) -> str:
			"""Get meta title of page/view"""
			return str(self.get_object())

As you can see, our code is calling the `get_object()` method. Where is that one defined? Not within our `MetaMixin`. If you would instantiate this class and call the `get_meta_title` method, an exception would be raised and the code wouldn't be running. We expect some other code to define this method somewhere. We expect our Mixin to be "mixed in" with other classes and other code.

For example, we could use our Mixin in the following manners:

	::python
	from .mixins import MetaMixin
	from .models import User

	class Foo(MetaMixin):
		def get_object(self):
			return User.get_user()

Or

	::python
	from .mixins import MetaMixin
	from .views import DetailView
	from .models import User

	class UserDetailView(MetaMixin, DetailView):
		model = User

In the first example, we are using the `MetaMixin` as the base class for a new class where we implement the `get_object` method ourselves while in the second example, we are using multiple inheritance to enhance the features of the `DetailView` class. In the second case, we expect the `DetailView` to already have implemented the `get_object` method that our Mixin depends on.

In either case, we can see that Mixins are used to enhance or to add features to another set of code. A mixin is not meant to be used by itself.

## When to use Mixins in Python?
So why would you want to implement mini-classes like this that only add parts of the full picture, and that can't be used on their own? When will we have a need for this type of behavior?

In general, there are 2 cases where you would like to implement something like this:

- You want to provide a lot of optional features for a class.
- You want to use one particular feature in a lot of different classes.

For example, let's talk more about web views and controllers just like in the previous case with the `DetailView` and `MetaMixin`. For views, there could be plenty of optional features that we might want to add to different views.

For example:

- Authentication.
- Support different HTTP Verbs.
- Return HTML responses from templates.
- Set context variables that will be used in templates.
- Get an object from the database that the view represents.

Instead of creating large classes that work with every combination of these features, or implementing them all in a single large class, we can instead compose our view classes with these features whenever they are needed.

For example, imagine that we have a web view for an e-commerce store that represents a single `Product`. This type of view might be required for other types of database models as well such as a `Customer`, `Category` or `Order`. It, therefore, makes sense to create some kind of reusable code that we can use to automatically fetch the object from the database, maybe we can automatically expect there to be a `slug` or `id` url parameter that we could use to figure out which unique object we want to fetch.

	::python
	from .views import View
	from .models import Product, Category, Customer, Order

	class SingleObjectMixin(object):
		model = None
		def get_object(self, request):
			if self.model is None:
				raise Exception("Model must be set.")
			return self.model.get(id=request.kwargs.get("id")

	class ProductView(SingleObjectMixin, View):
		model = Product

	class CategoryView(SingleObjectMixin, View):
		model = Category

	class CustomerView(SingleObjectMixin, View):
        model = Customer

	class OrderView(SingleObjectMixin, View):
		model = Order

Some of these views might also require authentication to be viewed, perhaps a user must be logged in to be able to see the details of an order. We can then imagine that we also have an `AuthMixin` that we could use to implement this behavior. We might, therefore, end up with the final code looking something like this:


	::python
	class ProductView(SingleObjectMixin, View):
		model = Product

	class CategoryView(SingleObjectMixin, View):
		model = Category

	class CustomerView(SingleObjectMixin, AuthMixin, View):
		model = Customer

   	class OrderView(SingleObjectMixin, AuthMixin, View):
		model = Order

As you can see, all of the new views that we have created inherit from the base `View` class, which contains the bulk of all logic or code required for our code to work. But all of them get unique behavior added to them in different ways using smaller Mixin classes that add specific, small sets of features to enhance the base class in different ways.

I hope this example illustrates a great use case for python mixins.

## What's the Definition of a Python Mixin?
As I was mentioning in the early parts of this article, a Mixin is not a "thing". It's just a class that is being inherited using traditional inheritance. Because of this, it can be tricky to lock down a very specific and official definition of what defines a mixin. 

I am not naive enough to claim that I somehow have that official definition, but we can list a few points of what makes mixins unique to help you also understand how, and when to use them properly.

- Mixins are tools to create classes in compositional styles.
- A mixin is meant to be "mixed in" to other pieces of code. It might run on its own, but it was not created with the intention to run on its own. 
- A mixin is a class that is implementing a small and specific set of features that is needed in many different classes.
- There is no limit on how many mixins you can use to compose a new class. You can use 1 or 10, it's all up to you as the developer to make that decision.

When you inherit multiple different mixins to your new class, it is important to remember the order which Python inherits these parents in.

	::python
	class Foo(FirstMixin, SecondMixin, BaseClass):
		pass

	class Bar(BaseClass, SecondMixin, FirstMixin):
		pass

These two examples do not necessarily create the same set of functionality, even though they inherit from the same classes and mixins. Since they inherit classes in a different order, it means that it might override methods that exist in more than one of the classes in different ways.

The recommended and "logical" way to structure the order of your inheritance is to make the highest to lowest from left to right. So if you want `FirstMixin` to have the highest precedence, it should be defined as the first item, following the `Foo` class definition.

## Mixins vs Decorators in Python
If you already have some experience with Python, you might notice that the use of Mixins has some similarities with the use of Python Decorators. Both are used to modify or add behavior that enhances or customizes another set of code.

In many cases, the use of a Mixin could also be replaced with the use of a Decorator or the other way around. So which approach is correct and when should you use what?

The main differences between Mixins and Decorators are:

- Decorators wrap functionality around a piece of code.
- Mixins add functionality to code using Inheritance.

There are some restrictions on each method.

- Mixins only work with Object-Oriented Programming and Classes.
	- You cannot use Mixins to modify a function or a method, only classes.
- Decorators cannot add new methods or new pieces of code.
	- A decorator just accepts a piece of code, modifies it and returns it. It cannot add something new. If you decorate Function A, you cannot simultaneously add Function B.

Because of these features and restrictions, it makes each method more suitable for some problems than others. Generally, you could say that decorators are most commonly used to modify the behavior of existing code while Mixins are used to add new behaviors. 

For example, a decorator might be used to register a function to some collection and then returning the same function, or perhaps taking a function or class and then modifying it before returning it back again.

A Mixin might be used to add a new set of methods to a class, instead of just modifying behavior it adds new blocks of code and new features to the existing class.

Also, in my opinion, Mixins are nicer to use for composing functionality of a new class. Theoretically, you could decorate a new class to compose it with functionality, but having a list of 5 decorators that wrap each other, is more confusing and difficult to understand than to use Mixins that compose the new behavior.

