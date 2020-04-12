---
layout: post
title: 6.8 Times Faster with Django Performance Optimization
date: 2019-02-27 00:00:00 +0000
categories: docker
permalink: /@marcus/68-times-faster-with-django-performance-optimization
---

Scaling Django in production to be able to serve your application to thousands of visitors is one of the most popular topics that people wonder and ask about within the Django community. I can't even count the times I've seen people ask questions related to this within Facebook groups, StackOverflow and other discussion forums.

Yes, Django scales incredibly well and we can see that from use cases such as BitBucket, Quora, Instagram, Disqus and other services that use Django to serve millions of requests to their visitors. However, unlike some people think when they start working with Django, this does not come for free out of the box.

To be able to have a high-performance Django website, you must follow many different best practices to improve many of the various aspects of building your application in Django. This usually mainly focuses on two things:

- Database Query Optimization
- Asset Bundling and Image Optimization

## Improving the Performance of This Website

Recently I spend a good amount of time to improve the performance of this very website that is serving you this article. After applying the performance techniques and practices listed in this Article I was able to change the load time from 6.02 seconds to merely 875ms. That's 6.9x faster!

![django performance optimization](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/performance_test.png)

This does not only make sure that the website loads faster in the browser, but it also puts less load on the web server and database server, which in turn means that you can serve more users for less money. All of these things are best practices that can be applied by any website.


### How to Debug and Test Load Speed of Site

To be able to know if the performance optimization of your Django website is improving the load speed or not, you first must have a way to measure the load speed for your site.

I recommend you to use the following tools to do this:

- [Django Debug Toolbar](https://github.com/jazzband/django-debug-toolbar/)
- [GTMetrix](https://gtmetrix.com/)
- [Pingdom Tools](https://tools.pingdom.com/)

### Install Django Debug Toolbar
Django Debug Toolbar is one of the most popular packages to use with Django, and it gives you great insights into what is going on with your website as you load a view. 

It will give you information such as:

- Database query information such as query count, duplicated queries, query speed, and raw SQL.
- CPU Load time of the page.
- Signals triggered.
- Static Files loaded.

All of this data can be used as a benchmark and to give insights into what it is that is slowing down your website, and where you have to put your effort.

[Follow the official install documentation](https://django-debug-toolbar.readthedocs.io/en/latest/installation.html) to install Django Debug Toolbar.

Personally, I prefer to split my development dependencies into a separate requirements file than the rest of my dependencies. This means that I can install them on my local development environment, and keep them out of my production environment. We definitely never want to use Django Debug Toolbar in production due to security vulnerabilities, so make sure that its installation is limited to the development environment.

### Use Pingdom Tools and GTMetrix
Pingdom Tools and GTMetrix are two great, free tools that allow you to benchmark the performance of your website. It simply acts as a browser and attempts to visit your website and record any request to give you insights into what can be improved.

The screenshots at the beginning of this article that illustrate the almost 7x speed increase are from Pingdom Tools.

You can use these tools to gather information such as:

- Total Load Time.
- File request count and size.
- Wait Time (How long it takes before the server gives the browser a response).
- Status of file cache headers.
- Status of compression.

## Pre-Load Relations with Your Database Queries
When I started out my load time was more than 6 seconds, I started by analyzing the requests to the website using Pingdom Tools and I realized that the wait time was over 2.6 seconds, this means that it took 2.6 seconds before the server even generated a response to the browser.

What this means is that your Django application takes 2.6 seconds to receive a request, query the database, apply business logic and return the response. This might sound quite fast, but remember that this is the time it takes before the browser even starts to load the site, so after this, the browser still must download all assets and load the actual HTML.

By using Django Debug Toolbar, I was able to see that a lot of this load time spent on SQL queries. To load a list of blog posts to display to the user, I had to do almost 40 database queries. Ouch!

A lot of these queries were duplicates, this could be because we have a list of objects, and as we iterate over each object we attempt to access a relation for each one. Each time we access a relation it then generates a new query, which creates duplicated queries.

For example:

	::python
	from .models import Article
	
	articles = Article.objects.all()
	for article in articles:
		print(article.author.username)

Imagine that `article` contains 100 articles. For each article, we attempt to get the `.author` field which is a relation to the `User` object. What Django then actually does, is that it creates additional database queries to fetch this user.

How could we improve this? By preloading the relations!

### Use select_related to Select Relations
Django has a great method named `.select_related()` which is located on the `QuerySet` object. What this method does is that it allows us to make a `JOIN` query that joins all of the relations of the list of objects that we are querying. 

Remember the last example above? We first do a query that loads 100 articles, and then for each article we do an additional query that load the author. That would create 101 queries!

We could reduce all of this down to a **single query** by using `.select_related()`.

	::python
	from .models import Article

	articles = Article.objects.all().select_related('author')
	for article in articles:
		print(article.author.username)

#### Only Work With Forward Relations
The `select_related()` method has some limitations, you cannot use it to load ManyToMany relations, and you can also not use it for reverse relations except on `OneToOneField`.

What this means is that if `Article` has the `author` field as a relation to the `Author` model, we can use `select_related()` from Article to Author, but we cannot use it to prefetch Articles **from** Author.

This means that it is important that you properly think through your Model and database table design to enable you to later optimize your queries using this great tool.

### Use prefetch_related To Select ManyToMany or Reverse Relations
As I was mentioning in the previous section, the `.select_related()` method only works with forward ForeignKey relations, you cannot use it to either do reverse lookups or to load ManyToMany relations.

Fortunately, Django doesn't just leave us hanging if we're in a situation where we need to do query optimization and preloading of these type of relations, for this we use `.prefetch_related()`. 

The `.prefetch_related()` method work very similar to the `.select_related()` method. You apply it to a `QuerySet` and it preloads the relations for you, which helps you reduce duplicated queries, however, the way it achieves this is completely different.

The way `select_related()` works is that it joins in the data using a single query. The way `prefetch_related()` works is that it creates a new query additional to your original one, and loads the related data in a separate query.

This means that by using `prefetch_related()` you can never get down to a single query, but you can greatly reduce the query count when there are many duplicates.

## Simplify Queries
Sometimes when we abstract writing SQL queries to an ORM we lose sight of what queries that are actually generated in the background, and two examples that might appear to look very similar in Python, might generate completely different queries that it sends to the database.

### Use exists() to Check Existence of Object
Let's take the Category pages of this website as an example. We might have many different category tags, but we only want to display a view for a tag if it actually has any articles that are tagged within it. We do this because we don't want to have a lot of empty pages throughout our site.

In this case, we don't necessarily care about the data, we just want to see if the Category has any articles related to it or not. In cases like this we should always use `.exists()`.

	::python
	# Good
	if category.articles.all().exist():
		print("Category has articles!"

	# Bad
	if len(category.articles.all()) > 0:
		print("Category has articles!")

	# Bad
	if category.articles.all():
		print("Category has articles!")

What `.exists()` does is that it reduces the query and limits it to fetch as few items as necessary to validate if the query return any objects or not. This can greatly improve your query.

### Consider .first() vs [0]
Let's say that you have a list of items returned from a query and you want to limit it to 1 and only get the first one. There are 2 ways of doing this which are incredibly similar.

	::python
	Category.objects.all().first()
	Category.objects.all()[0]

These queries generate almost the exact same query and they perform almost identical, however! I've noticed differences with using them in combination with `prefetch_related` and `select_related`. 

If you're unable to reduce queries using prefetching techniques listed above, you can try to replace `.first()` with index access (`[0]`) and see if it helps Django to identify the duplication of queries, and help you reduce the duplications.

## Enable Gzip Compression of HTML and Assets
After reducing any duplication of database queries it was time to move on to the static assets that we were serving. As you can see from the initial benchmarks, our website was loading 1.5mb of assets on each request. 

I use `django-storages` to store all of my media and static files on a DigitalOcean Spaces S3 instance ([Read this article to learn how to set this up](https://coderbook.com/@marcus/how-to-store-django-static-and-media-files-on-s3-in-production/)).

This means that before I even started my optimization process, I already leverage a CDN and remote cloud storage to host and serve all my assets. This by itself is a great way to reduce the load on your web server, and to speed up asset delivery.

Until now, even if I was leveraging this cloud storage to serve my files, I still had not optimized the files properly by compressing them using Gzip compression. By doing this we could reduce the size of the files even more.

### Enable Gzip Compression of Django Storages
To enable Gzip compression on files stored using `django-storages`, all you have to do is to enable the `AWS_IS_GZIPPED` option. 

On top of this, I also add cache headers to each file controlled by `django-storages` to make sure that browser cache is enabled for all of my files. This means that the options I add to optimize my file delivery using this package is the following:

	::python
	AWS_IS_GZIPPED = True
	AWS_S3_OBJECT_PARAMETERS = {
		'CacheControl': 'max-age=86400',
	}

That's it! This amazing module makes it incredibly easy for us to make sure that our assets are served in an optimal way.

### Enable Gzip Compression of Django HTML
What about the rest of our response? Obviously, the static asset files such as images, CSS stylesheets or Javascript is the bulk of our response size in terms of kilobytes or megabytes, but we also have the HTML itself.

Django has a GzipMiddleware that we can enable that then makes sure that the response itself is compressed using Gzip before it's delivered back to the client. This is a one-liner that you can add to your `MIDDLEWARE` list which is also a no-brainer.

	::python
	MIDDLEWARE = [
		'django.middleware.gzip.GZipMiddleware',
		...
	]

It is recommended that you add the `GZipMiddleware` as early in your list of middlewares as possible, to make sure that it compresses as much data as possible.

By this small addition, I was able to reduce my HTML kilobyte size by 4.5x. 

## Generate Thumbnails for Uploaded Images
After making sure that the delivery of our images is compressed and minimized, it is time for us to take a look at optimizing the images themselves.

Do you see the author portrait that is presented next to each blog post on this website? The image itself might be uploaded in 600x600 resolution, but it is only displayed in 60x60 resolution. Why would we want to load an image that is 10 times larger than the format that we're displaying it in?! That's a huge waste.

The solution to this is to make sure that each file served is only served in the exact dimensions that it's required and displayed in on the actual website. We can achieve this by using thumbnails.

But isn't this a pain in the ass? What if we display the portrait photo in 60x60, 120x120, 240x240 and 600x600 depending on which page you are or what device you're using? Do we need to upload a unique image in each resolution?

No, the solution to all of this is to use a beautiful little packaged named [sorl-thumbnails](https://github.com/jazzband/sorl-thumbnail). By using this plugin we can generate thumbnails on the fly the first time they are requested, and then store them in a cache for each subsequent request.

I've already written [a detailed guide of how you set up this package in Django](https://coderbook.com/@marcus/generate-thumbnails-automatically-in-django-with-sorl-thumbnail/).

## Use Optimal File Types and File Quality
By default, the `sorl-thumbnail` package is using some settings that might not be optimal for reducing the file size of all of your images to the maximum. 

There are 2 main things that control the image file size except for its dimensions:

- The file type that the image is stored in (PNG, GIF, JPEG)
- The quality that the file is stored in.

I would say that using the correct file type for the right type of images is of more importance than image quality when it comes to reducing the file size.

Determining the file type that you should use is quite easy if you follow these rules:

- Is it a photo of millions of colors? Use JPEG.
- Is it an icon, illustration, or a simple image? Use PNG.

Unfortunately, by default `sorl-thumbnail` convert all of the files that you use with it to JPEG format, on top of this it also stores it in quality `95` which is considered very high and almost lossless. 

This results in that your uploaded PNG files might even **increase** in file size after you start using `sorl-thumbnail`. To take care of this you must use the following settings:

	::python
	THUMBNAIL_QUALITY = 85
	THUMBNAIL_PRESERVE_FORMAT = True

The `THUMBNAIL_QUALITY` value is something that you might need to experiment with to determine the acceptable level. The lower value, the smaller size, but it will also make your files a lower quality.

The `THUMBNAIL_PRESERVE_FORMAT` option will make sure that any files that are uploaded in PNG format, will get PNG thumbnails, and any file that is uploaded in JPEG format will get JPEG thumbnails.

## Add Pagination to Speed Up Website
So far in this article, we've been talking about a lot of technical details of how you can optimize the performance of your Django application. These type of optimizations are usually the first thing that Software Engineers come to think of and start spending their effort on.

Surprisingly, the main thing that had the largest impact on the response time of the website had nothing to do with optimizing queries or images, it was a restructuring of the page itself.

By implementing pagination of the blog posts and adding "Next" and "Previous" buttons that allowed the client to navigate back and forward and only load a subset of articles at a time, we were able to reduce the number of queries and the number of static files at the same time.

Instead of loading ~50 blog posts on a single page, we could reduce it to only 10, which means that there were fewer images, HTML and database queries to load.

As you could see from the benchmarks at the beginning of this article, by limiting the number of posts loaded on a single page we were able to reduce the file asset requests from 46 to 24, a reduction of almost 50%!

Out of this whole article, this had the single largest impact on the load speed of my web application. No matter what type of web application you have, you can probably learn something from this. Reduce the data you display on any page, and you will get a lot of these optimizations for free.

## Summary of Performance Achievements
In the end I was able to achieve plenty of performance improvements using these techniques that helped me reduce the load time of my site from over 6 seconds to less than 1 second, and all of this without even enabling cache!

Some of the benchmark improvements from all of these changes are:

- Reduce query count from 40 to 9.
- Reduce page size from 1.5 MB to 492 KB
- Reduce asset requests from 46 to 24
- Reduce HTML size by 75%
- Reduce Wait Time from 2600 ms to 444 ms

And like I said, this is all without using things such as File Cache, Redis or MemCache that would speed up the performance of the website even more.

