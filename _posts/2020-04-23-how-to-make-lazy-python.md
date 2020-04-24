---
layout: post
title: How to make Lazy objects in Python
date: 2020-04-23 00:00:00 +0000
categories: python
---

Lazy evaluation is an interesting topic that can be a little bit difficult to understand
at first glance, it is quite common for me to have to help people who misunderstand when
their code is executed -- since they use lazy technologies such as Spark Dataframes or
Django ORM.

Lazy evaluation can be explained quite simply as *"Wait with evaluating value until its needed"*.

## What are Lazy Objects in programming?

Isn't *"Wait with evaluating value until its needed"* clear enough?

Let's take a look at two common technologies that you might have experience with in the past
to see lazy behavior in action, [Django](https://djangoproject.com/) and [PySpark](https://spark.apache.org/docs/latest/api/python/index.html).

```python
# Example using Django models to query
# a database for customer information.
from .models import Customer

def get_customers(active=False):
    customers = Customer.objects.all()
    if active:
        customers = customers.filter(active=True) 
    return customers
```

Here we are using the Django ORM to query customer data. If you're new to Django you might
look at this code and think that it queries the database twice, first it gets all customers
and then it do a second query to get a subset of the active customers. This is incorrect!

Our `customers` object is not evaluated until we actually try to read the data. Until then,
the `customers` object is just a query instance that can continue being modified and it only
hits the database once we actually attempt to do something like:

```python
# Only now do we actually execute our
# query. Until now the `customers` has
# been LAZY.
for c in customers:
  print(c.name)

```

The benefits of this is obvious in the case of querying a database. Instead of having
to query the database over and over again every time we modify our query, we can save
all interactions until we finally know the final query we want to do, and only do it then.

Our second example is with PySpark where we can see lazy evaluation in action when using
Spark Dataframes. Similar to the Django example, Spark leverage lazy evaluation to avoid
having to do calculations in the spark cluster on every change to the dataframe, and instead
it awaits until the data need to be accessed to finally evaluate it.

```python
from .connections import spark

def get_customers(active = False):
    df = spark.read.csv("customers.csv")
    if active:
        df = df.filter("active = False")
    return df

```

Once again, for the new user you might think that this code first reads in the .csv file
in one large operation, and then filters it in a second call to the cluster. This is incorrect and
it's not what happens! Instead, Spark waits with evaluating our `df` object until we need to access
the data with something like `df.count()` or `df.collect()`. 

The benefits of this are equal to our Django ORM example, we can avoid doing multiple requests
to our cluster, and we can wait until we have all the information we need and then do a single,
optimized request to our spark cluster in the end right before we access the data.


## When should I use Lazy Evaluation?

The pattern that you might see from the two examples above is that lazy evaluation is used
when we want to *defer* the execution of our code until a later stage. This could be good
in a number of different scenarios such as:

* You don't have all the information yet. Maybe further down the code something else
  is modified or added.
* Performance optimization, avoid doing multiple calculations or requests and gather
  everything into a single request.
* Avoid executing code when it is not used or needed.

The third point can be illustrated with the following example:

Let's say that we have a codebase that rely on a Spark connection to a spark cluster to
distribute computation of dataframes. We define this connection in our `connections.py`
file and import it across our codebase wherever it is needed.

```python
# connections.py
spark = (
    SparkSession.builder
                .config(conf=spark_config)
                .appName(os.getenv("APP_NAME", "default"))
                .getOrCreate()
)
```

```python
# app.py
from .connections import spark

def calculate(self):
    # Placeholder for complex spark computations.
    return spark.createDataFrame()

def util_func(self):
    # Placeholder for some common util function.
    return True
```

When is this spark connection opened? It is executed as soon as it is imported, meaning
the first line of our document will pause execution, open a spark connection (which takes a few seconds)
and only after that continue reading the function definitions of our `app.py` file.

Even worse, when anyone try to import anything from our `app.py` file, it will stop the execution,
open our spark connection for a few seconds and then complete the import. 

So in the example above, if someone want to import our `util_func`, it will be forced to
open a spark connection that will never be used in that perticular use case.

The solution to this is to make our Spark connection lazily evaluated, and only open the
connection when it is actually required.

```python

def get_spark_connection():
    return (
        SparkSession.builder
                    .config(conf=spark_config)
                    .appName(os.getenv("APP_NAME", "default"))
                    .getOrCreate()
    )

spark = LazyObject(factory=get_spark_connection)
```

The idea is that we create a `spark` object that is importable from anywhere, but the
object does not actually contain our `SparkSession`. It contains a `LazyObject` instance
that later initiates the `SparkSession` using the `get_spark_connection()` function
whenever it is needed.

By doing this, we can now globally import our `spark` object at the top of our files without
slowing down the execution of our code.


## Implementing Lazy Objects in Python

In the previous example we used a custom `LazyObject` class to wrap a factory function and
implement lazy behavior in Python. Let's take a look at how this `LazyObject` class might look
like.

```python
import operator

class LazyObject:

    _wrapped = None
    _is_init = False

    def __init__(self, factory):
        # Assign using __dict__ to avoid the setattr method.
        self.__dict__['_factory'] = factory

    def _setup(self):
        self._wrapped = self._factory()
        self._is_init = True

    def new_method_proxy(func):
        """
        Util function to help us route functions
        to the nested object.
        """
        def inner(self, *args):
            if not self._is_init:
                self._setup()
            return func(self._wrapped, *args)
        return inner

    def __setattr__(self, name, value):
        # These are special names that are on the LazyObject.
        # every other attribute should be on the wrapped object.
        if name in {"_is_init", "_wrapped"}:
            self.__dict__[name] = value
        else:
            if not self._is_init:
                self._setup()
            setattr(self._wrapped, name, value)

    def __delattr__(self, name):
        if name == "_wrapped":
            raise TypeError("can't delete _wrapped.")
        if not self._is_init:
                self._setup()
        delattr(self._wrapped, name)

    __getattr__ = new_method_proxy(getattr)
    __bytes__ = new_method_proxy(bytes)
    __str__ = new_method_proxy(str)
    __bool__ = new_method_proxy(bool)
    __dir__ = new_method_proxy(dir)
    __hash__ = new_method_proxy(hash)
    __class__ = property(new_method_proxy(operator.attrgetter("__class__")))
    __eq__ = new_method_proxy(operator.eq)
    __lt__ = new_method_proxy(operator.lt)
    __gt__ = new_method_proxy(operator.gt)
    __ne__ = new_method_proxy(operator.ne)
    __hash__ = new_method_proxy(hash)
    __getitem__ = new_method_proxy(operator.getitem)
    __setitem__ = new_method_proxy(operator.setitem)
    __delitem__ = new_method_proxy(operator.delitem)
    __iter__ = new_method_proxy(iter)
    __len__ = new_method_proxy(len)
    __contains__ = new_method_proxy(operator.contains)
```

Looks like quite a bit of code, but it should be quite easy to understand.

* Our `LazyObject` take a factory method as a argument in `__init__`. This factory method
  is the function that instantiate the object that we want to be lazy. For example we 
  could do `LazyObject(lambda: Context())` to provide a factory that instantiates a `Context`.
* Whenever we interact with any of the dunder methods (e.g. `__setattr__`, `__getattr__`, `__len__` etc)
  we call `_setup()` which finally instantiates our object using the factory method. This means
  that we defer any instantiation until we for example try to get a value using `__getattr__`.
* Methods are routed to the `_wrapped` object using the `new_method_proxy()` utility function.
  This means that if we for example call `len()` on our `LazyObject`, it will actually route that
  call to call `len()` on our wrapped object.


The final result in practice looks something like this:

```python
context = LazyObject(lambda: Context())

# Do some other stuff. Context is not evaluated yet.
some_other_code()

# Only now is Context instantiated and evaluated,
# since we attempt to access an attribute on it
# using __getattr__ which in turn calls _setup().
print(context.run_id)
```
