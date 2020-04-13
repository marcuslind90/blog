---
layout: post
title: How to Create a Hash Table From Scratch in Python
date: 2019-01-21 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-create-a-hash-table-from-scratch-in-python/
---

A Hash Table is one of the core data structures that you need to have a good understanding of as a Software Engineer. Unlike some other data structures that are rarely used in real life situations, Hash Tables are used all the time.

For example, by using a dictionary in Python like `data['key'] = 1` you are actually using a hash table. The way Python handles it in the background is hashing that key that you used and then it tries to figure out how to store the value in a traditional array.

So what is the lookup time of a Hash Table? What is the time it takes add values? Perhaps you know the answers to those questions, but even if you do, do you really feel confident that you have a good grasp of why those answers are true?

Why does Hash Tables have constant O(1) lookup time? The best way to properly understand these things is to try to create our own implementation of a Hash Table. Then we'll truly understand how things are working behind the scenes.

In this article I will create a custom Hash Table class with Python, however this could be done in any other language. We will try to emulate the behavior of how a dictionary works.

## Planning our HashTable Class
The first step is to initiate our class and to think about how we will achieve what we're trying to do. Obviously we are not allowed to use Python dictionaries or any other data type that rely on Hash Tables, since the whole point of this exercise is to create one of our own.

This basically means that it all comes down to storing values in a list/array. But how do we store key value pairs in a list? We could store them as key value pairs, but how do we know where each pair is? Isn't list just a sequence of values?

For example:

```python
values = [("foo", 1), ("bar", 2), ]
```

Lists doesn't use keys, it uses indexes. You can only access a value in a list by the index or position that it's stored at. E.g. `values[1]` would be `("bar", 2)` in the example above.

So what if we instead wanted to be sure that we could access each key value pair by its key. Another way to look at it would be to ask ourselves "How can we figure out which index we should store a value in by a string key?. Think about that for a moment.

The answer to this is that if we already know the size of the list, we can generate a number representation of our string and then splitting it with modulus `%` by the size of our list. That would then give us a index position that our value should be stored in.

The important part is that this code is repeatable and that we get the same position over and over again with the same key. If `foo` says that we should store our values in `[0]` the first time, its important that it returns `[0]` the second time again, so that we can feel confident that we always know how to lookup our value.

An example implementation of this would be:

```python
ARR_LENGTH = 4
# Initiate array
values = [None] * ARR_LENGTH

def get_index(key: str):
    return hash(key) % len(values)
```

This would always return an index that exist within our `values` list. Note that the python `hash` function returns an integer.

By knowing this, we can now start implementing our Hash Table class.

## Initiate HashTable Class

Let's get going! From our planning session above, we already know how we will figure out the index based on the string key value given. But we also have to realize that it definitely could be some collisions.

For example, if you have a list of length 2, chances that 2 strings will want to use the same index is 50%. Therefore, we can't just simply store a single value by index, instead we will store a list of key value pairs for each index. 

Eg:

```python
    self.array [
        [("foo", 1), ("bar", 2), ], 
        [("hello", 3), ("world", 4), ], 
    ]
```

Great, let's get going then with the first part of our implementation. I will start by implementing `__init__()`, `hash()`, `add()` and `get()`. 

```python
class HashTable(object):
    def __init__(self, length=4):
        # Initiate our array with empty values.
        self.array = [None] * length
    
    def hash(self, key):
        """Get the index of our array for a specific string key"""
        length = len(self.array)
        return hash(key) % length
        
    def add(self, key, value):
        """Add a value to our array by its key"""
        index = self.hash(key)
        if self.array[index] is not None:
            # This index already contain some values.
            # This means that this add MIGHT be an update
            # to a key that already exist. Instead of just storing
            # the value we have to first look if the key exist.
            for kvp in self.array[index]:
                # If key is found, then update
                # its current value to the new value.
                if kvp[0] == key:
                    kvp[1] = value
                    break
            else:
                # If no breaks was hit in the for loop, it 
                # means that no existing key was found, 
                # so we can simply just add it to the end.
                self.array[index].append([key, value])
        else:
            # This index is empty. We should initiate 
            # a list and append our key-value-pair to it.
            self.array[index] = []
            self.array[index].append([key, value])
    
    def get(self, key):
        """Get a value by key"""
        index = self.hash(key)
        if self.array[index] is None:
            raise KeyError()
        else:
            # Loop through all key-value-pairs
            # and find if our key exist. If it does 
            # then return its value.
            for kvp in self.array[index]:
                if kvp[0] == key:
                    return kvp[1]
            
            # If no return was done during loop,
            # it means key didn't exist.
            raise KeyError()
```

This should be pretty straight forward and self explanatory with the comments added, but just to summarize quickly what we are doing:

- In `__init__` we initiate our list with a fixed length of 4. Each index contain a `None` value which represents that no values exist in that index yet.
- `hash()` follows the implementation that we described previously. We hash a string into an integer value, and then we split that by the amount of positions we have in our index, to figure out where we should store the key value pair.
- `add()` uses the `hash()` method to add a key value pair to a specific index within our list. If values already exists within that index it tries to figure out if it should update a value. If not, it just adds the key value pair to the end of the list.
- `get()` attempts to find the key within our list to return the value. If it doesn't find it, it will raise a `KeyError` exception just like a normal Python dictionary does.

This is a pretty minimal implementation of a hash table in Python, however if you have a good eye for things you will notice some performance issues. Isn't Hash Tables suppose to have a constant speed for adding and reading values?

If we look at the `add()` and `get()` method we can see that both of them need to loop through existing key value pairs. If we have a lot of collisions of indexes, it means that some of these lists of key value pairs might be very long. That means that our lookup would be linear (the time it takes to lookup a value would increase linearly with the amount of values stored) instead of being constant.

How do we solve this?

## Reduce Collisions in Hash Table
If we take a look at our code we can see that we initiate our `self.array` with a list of length 4. This means that its less only 25% chance that our second key value pair added will collide with the same index as the first one. But what happens when we add a third one?

Suddenly half of our indexes are already populated, so the chance of a collision is 50%! We soon get to 100% chance of collisions as all indexes are populated and we will now start doing linear lookups as we loop through each list of values, instead of constant lookups.

But what if we increased the size? Instead of starting with size 4, why don't we just start with size 1024 or greater? Wouldn't that greatly reduce our collision risk? Yes it would, but that would also mean that even the smallest Hash Table would reserve a relatively high amount of memory. 

On top of that, what if you wanted to store a million values? 1024 still wouldn't be enough.

The solution to this is that we make the size of our list flexible. We allow it to expand whenever it determines that its too populated. This means that we can always guarantee that the risk of collision is below a certain threshold. We can start with a length of 4, but then we can double it to 8, 16, 32, 64, 128, 256, 512, 1024, 2048 and beyond whenever we need to.

Lets implement the `is_full()` and `double()` methods to our `HashTable` class.

```python
class HashTable(object):
    
    ...
    
    def is_full(self):
        """Determines if the HashTable is too populated."""
        items = 0
        # Count how many indexes in our array
        # that is populated with values.
        for item in self.array:
            if item is not None:
                items += 1
        # Return bool value based on if the 
        # amount of populated items are more 
        # than half the length of the list.
        return items > len(self.array)/2
        
    def double(self):
        """Double the list length and re-add values"""
        ht2 = HashTable(length=len(self.array)*2)
        for i in range(len(self.array)):
            if self.array[i] is None:
                continue
            
            # Since our list is now a different length,
            # we need to re-add all of our values to 
            # the new list for its hash to return correct
            # index.
            for kvp in self.array[i]:
                ht2.add(kvp[0], kvp[1])
        
        # Finally we just replace our current list with 
        # the new list of values that we created in ht2.
        self.array = ht2.array
```

What did we just do?

- `is_full()` determines if we have the need to double/increase the size of our list or not. In our case we determine that our list is full whenever its more than 50% populated, but you could change this threshold to a lower or higher value if you wanted to.
- `double()` increases the size of our list by a factor of 2. What this mean is that if our list was 4 items long, it will now be 8. Since our `hash()` method determines the index of a key by splitting its hash with modulus of the length of the list, it also means that we have to re-add each key value pair to their new "correct" position.

Obviously it takes some time to double our list, but it happens relatively rarely, which makes it a better option than to iterate over all our key value pairs that are colliding with each other on every single read/write.

Finally we can start using our methods within our `add()` method by extending it with the following:

```python
class HashTable(object):
    ...
    
    def add(self, key, value):
        ...
        if self.is_full():
            self.double()
```

That means that whenever we have added an item that made our list hit the limit of what it consider to be "full", it will automatically double the size of itself. We are now done with the core implementation of our HashTable.

## Add Additional Methods
By now you should have a good enough understanding of our Hash Table to be able to extend it with your own functionalities. For example, you could use Python's magic methods such as `__getitem__`, `__setitem__`, `__iter__` and `__contains__` to implement the additional behavior to make your `HashTable` class more properly emulate the standard dictionary in Python.

By doing this you could do things such as:

```python
ht = HashTable()
# Using __setitem__
ht["foo"] = "bar"

# using __getitem__
val = ht["foo"]

# using __contains__
if "foo" in ht:
    print("Exist!")
    
# using __iter__
for kvp in ht:
    print(kvp)
```

In the case of our `HashTable` class we could implement `__setitem__` and `__getitem__` with our existing `get()` and `add()` methods.

```python
class HashTable(object):
    ...
    def __setitem__(self, key, value):
        self.add(key, value)
    
    def __getitem__(self, key):
        return self.get(key)
```

Maybe you could implement the other recommended magic methods on your own as an exercise to prove to yourself that you truly understand how Hash Tables are implemented.
