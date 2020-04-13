---
layout: post
title: Python Tips and Tricks for Path and URL Parsing
date: 2019-03-02 00:00:00 +0000
categories: docker
permalink: /@marcus/python-tips-and-tricks-for-path-and-url-parsing/
---

Parsing file paths, web addresses or file names is something that we have to come back to over and over again in different situations. It could be that you want to validate the file extension of a file name, or perhaps that you want to get a hostname of a full URL.

There are plenty of different methods to break down a string of a path into smaller components, to allow you to get the information you'd like. A lot of the time this kind of code can get quite messy with splitting, checking and merging different parts together.

When you manually parse your paths or URL's and pass them between different methods and classes, it also increases the chance that mistakes happen. For example, let's say you want to merge a URL hostname with a File Path to construct a complete, absolute URL to the file. Does the path name start with a slash? Should we always strip slashes to make sure that we don't end up with double slashes (e.g `http://url.tld//path/to/file.ext`)?

Python has a great set of tools that come packaged with the language these days that simplifies all of these actions, and help us write shorter, cleaner code that is tested and perform better.

In this article, I'll go through some common tasks that you can use Python's built-in tools to solve related to paths, file names and URL's.

## Create and Concatenate Paths using pathlib.Path
An incredibly common task is to concatenate strings to create a complete path, this is usually done when you want to do a file upload and merge directory path with a file name.

For example:
	
	::python
	path = "{}/{}/{}".format(
		get_upload_path(),
		"inputs",
		file.name
	)

Our intention in the code example above is to create a path that look something like `/static/files/inputs/myfile.png`. But can we really be sure that we will achieve this? What happens if `get_upload_path()` returns a path with a trailing slash?

In that case, the final URL would look something like `/static/files//inputs/myfile.png`. It might still work, but it's not very pretty. 

On top of this, the code itself is not very easy to read. By giving it a glance, you can't really see that we are constructing a file path.

To solve all of these things, I prefer using the `pathlib.Path` class.

We could rewrite the code above to take advantage of `pathlib.Path` in the following manner:

	::python
	from pathlib import Path

	path = Path(get_upload_path()) / "inputs" / file.name

Do you agree with me that that's more readable? On top of that, the `Path` class will take care of things such as double slashes or other minor things that could cause unexpected behavior in our path.

A small note though, `Path` has implemented the `__str__` magic method to return a string path. This means that in theory a lot of the time you can just pass this `Path` object around and it will work fine, but personally, I feel that it's a good idea to convert it into a string when you are "done" with manipulating it. 

## Getting the file name of a Path or URL
Another common task is to parse a full path or URL to a file, and only want to get the actual file name.

This is yet another thing that is commonly done manually in different ways:

	::python
	file_path: str
	file_name = file_path.split("/")[-1]

Once again, this is a fairly simple thing to do but there are definitely some edge cases that this snippet of code will not cover and questions to ask ourselves.

- What if you're on a Windows system and `file_path` contains a path with forward slashes, e.g. `C:\files\file.png`?
- What if we only want part of the file name, e.g. `myimage` out of `myimage.png`?
- Is it readable and clear that we're getting a file name?

The first point regarding Windows file systems would require us to do `.replace()` calls and convert our path to a UNIX path, which by itself would be a bit weird and confusing to any developer who comes along and sees the code.

The second point also illustrates how we would have to complicate our code further to get what we wanted. You can imagine that by adding additional `.split()` chained to what we already have, would definitely not improve its readability. 

Finally the third point. I guess technically, as it is in the code example above, it is still quite readable. Most programmers would be able to figure out what it does just based on the variable name of `file_name`. But what if we also cover all the corner and edge cases? Would that be readable? 

All of this can be simplified with a single line of code:

	::python
	from pathlib import Path

	file_name = Path(file_path).name  # myfile.png
	file_stem = Path(file_path).stem  # myfile

Which alternative is more readable and take care of more edge cases? I think we can all agree that the `pathlib.Path` class simplifies this code by a lot, while also making it more readable and more robust.

## Getting the File Extension of a File Name or Path
One of the simplest, most reoccurring forms of validations when it comes to file uploads is to at least validate the extension of the file name. This might not be "enough", but it's at least a minimum thing to do, and it's something that we'll have to do over and over again throughout our projects.

Once again, the "common" way to get a file extension is by using `split()`

	::python
	file_path: str
	file_ext = f".{file_path.split('.')[-1]}"  # .png

Is that good enough? It might work for a normal case where we have something along the lines of `/file/myimage.png` but what about the edge cases?

- What if someone uploads a file to `/file/.gitignore`, is `.gitignore` a file extension or a file name?
- What if someone uploads a file to `/file/Dockerfile` without any dots. Is `Dockerfile` a file name or a file extension?

In both these cases, the answer is that No these are not extensions, they are file names. Both `.gitignore` and `Dockerfile` are files with names, but without extensions. 

There are two built-in libraries in Python that can help us parsing the file extension of a file name. The first one is `os.path`

	::python
	import os

	_, file_ext = os.path.splitext(file_path)

Unlike our own code written above, the `splitext()` method will return `''` as file extensions for the edge cases described (which is correct!). The only "downside" to me is that it returns a tuple and I have to ignore the first part most of the time, which reduce the readability of the code slightly.

The second library that we can use to get file extensions of files is once again our `pathlib.Path` class. It's just as easy as all the other examples of where this class has been used.

	::python
	from pathlib import Path
	
	file_path: str
	file_ext = Path(file_path).suffix

This method also handles the edge cases that we described above in a perfect manner and is as robust as things could be. This is my preferred method do parsing of file extensions.

## Parsing URL Schema, Hostnames, and Paths
Technically you can use the `pathlib.Path` class described in the other sections above to also parse certain parts of a full URL.

For example, let's say that you want to get the file name to a path that is an URL and not just a file path:

	::python
	from pathlib import Path
	path = Path("https://coderbook.com/files/file.png")
	path.name  # file.png

But what about parsing other sections of the URL? For example, let's say you want to get the scheme, hostname or the path of an URL? For this, `pathlib` is not the correct tool in your toolbox. 

This is where `urllib` comes in! As you can see from the name of the two modules, the intended use case of each one becomes pretty clear.

Using the `urllib.parse.urlparse` function we can easily parse a full URL to its different sections.

	::python
	from urllib.parse.urlparse

	sections = urlparse("https://coderbook.com/@marcus/blog-post/")
	sections.scheme  # https
	sections.netloc  # coderbook.com
	sections.path  # /@marcus/blog-post/

This can be incredibly useful. On this exact website that you're reading this article right now, this is one of the methods that is used to determine if `<a>` tags within articles should have `rel="nofollow"` or not. We can identify hostnames easily and determine what are internal links, what are external links, and which hostnames that are trusted and deserve a follow link and which ones doesn't.

### Parse GET Parameters from URL String to Dictionary
There are many cases where you might get a URL string from some source, and you want to parse the query parameters that are part of the URL into a dictionary that you can work with easier within your python code.

Imagine that you have a URL like this `https://coderbook.com/@marcus/python/?page=1`, and you want to convert it into something similar to `{'page': 1}`. 

Technically, you could write your own script that maybe split things by `?` and then split things additionally by `&` and then finally also split each value by `=`, and that would have then given you the key-value pair of each GET query parameters within the URL. That sounds messy and annoying, doesn't it?

Instead, we can actually leverage the `urlparse` function used earlier together with the `parse_qs` function that is also part of the `urllib.parse` module.

	::python
	from typing import Dict, List
	from urllib.parse import urlparse, parse_qs

	url: str
	params: Dict[str, List]

	params = parse_qs(urllparse(url).query)
	#  {"page": [1]}

That's it! Way simpler than having to do all these weird splitting that is so common to see in different codebases.

## Conclusion
I hope that all of these examples given in this article has removed any excuses from you to keep going on with the manual, tedious, and fragile ways of parsing paths, url's and files.

All of these methods will simplify your code, make it shorter, more readable and more robust. There is no reason not to use them for any code that you write from now on and forward.
