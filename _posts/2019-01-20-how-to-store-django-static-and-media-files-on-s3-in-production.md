---
layout: post
title: How to Store Django Static and Media Files on S3 in Production
date: 2019-01-20 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-store-django-static-and-media-files-on-s3-in-production/
---

Storing your static or media files on a remote storage in the cloud such as Amazon Web Services S3 or DigitalOcean Spaces is one of the first things that I recommend you to do when you setup a new Django project that is ready to go into production.

Storing your media files on a remote storage instead of together with your application on your web server give you a lot of great benefits such as:

- Better performance. Your web server can focus on delivering files while your files can be delivered with a Content Delivery Network (CDN).
- Improved migrations and deployments. You can always change, add or remove servers from your infrastructure without having to worry about access to your files. You can also easily change host providers without necessarily having to be concerned about migrating all your files.
- More secure. By not allowing users to upload their files to your web server that could potentially execute files, you are limiting your exposure to malevolent behavior.

No matter how small your project is, in my opinion it is a no-brainer to setup remote storage of files, especially since the cost of doing so is relatively minimal in the beginning when you probably have quite few files to store.

## Use django-storages to store files in cloud
[django-storages](https://github.com/jschneier/django-storages) is a great package that support remote file backends for many different cloud providers. I have personally used it for many projects and it's a package I'd love to recommend to anyone who work with production level web applications created in Django.

At the time of writing this article, the package support the following providers:

- Amazon Web Services S3
- Apache Libcloud
- Digital Ocean Spaces
- DropBox
- FTP
- Google Cloud Storage
- Microsoft Azure Blob Storage
- SFTP


### Installing django-storages
For our example below I will show you how to implement remote storage at a S3 cloud provider such as either DigitalOcean Spaces or AWS S3 (Both of these storages use the same S3 command and require identical configurations). If you plan to store your files on either one of these providers you need to also install the `boto3` dependency.

The installation of `django-storages` with its S3 dependency `boto3` is very easy. Just use the following commands.

	::bash
	# Note that there may be new versions of the
	# package at the time of reading this article.
	pip install boto3>=1.9.79
	pip install django-storages>=1.7.1
	
Unlike many other Django packages, you **do not** need to add this package to your `INSTALLED_APPS` settings.


### Configure django-storages to store files on S3
Note that the following settings use `AWS_` as prefix. This indicate that the settings are specific for Amazon Web Services. Unfortunately this is a bit misguiding, in reality the settings is specific for the `S3Boto3Storage` backend class, which will work with any S3 storage including:

- DigitalOcean Spaces
- Amazon Web Services S3

This means that no matter which one of these providers you use, you will use the settings that I show here below.

	::python
	DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
	STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
	
	# Used to authenticate with S3
	AWS_ACCESS_KEY_ID = os.environ.get('S3_ACCESS_KEY_ID')
	AWS_SECRET_ACCESS_KEY = os.environ.get('S3_SECRET_ACCESS_KEY')
	
	# Configure which endpoint to send files to, and retrieve files from.
	AWS_STORAGE_BUCKET_NAME = 'mybucket'
	AWS_S3_REGION_NAME = 'sfo2'
	AWS_S3_ENDPOINT_URL = f"https://{AWS_S3_REGION_NAME}.digitaloceanspaces.com"
	AWS_S3_CUSTOM_DOMAIN = f"{AWS_STORAGE_BUCKET_NAME.{AWS_S3_REGION_NAME}.digitaloceanspaces.com"
	AWS_LOCATION = 'files'
	
	# General optimization for faster delivery
	AWS_IS_GZIPPED = True
	AWS_S3_OBJECT_PARAMETERS = {
		'CacheControl': 'max-age=86400',
	}

Let's go through all of these settings together to make sure we have a proper understanding of what we're actually doing. 

- `DEFAULT_FILE_STORAGE` is the file storage backend for Media files. Media files in Django are the files that the user uploads to your service. This could be things such as profile images, videos and more. This should point to the class that you want to use to manage the files.
- `STATICFILES_STORAGE` is the file storage backend for Static files. Stattic files in Django are files that are part of your application. This could be things such as CSS files, Javascript files, website graphics, fonts and more. This should point to the class that you want to use to manage the files.
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. These are your credentials that you use to communicate with your S3 bucket. You receive these credentials from your cloud provider. In my case I fetch them from environment variables to make sure that they are secret and protected.
- `AWS_STORAGE_BUCKET_NAME` is the bucket name on Amazon S3 or spaces name on DigitalOcean Spaces. This is the instance of where your files will be stored.
- `AWS_S3_REGION_NAME` is the region of where your bucket or spaces are located. Both DigitalOcean and AWS use regions such as "nyc3" or "sfo2" on DigitalOcean and "eu-west-1" or "us-east-1" on AWS.
- `AWS_S3_ENDPOINT_URL` is the endpoint that Django will use to communicate with your storage. This is not necessarily the endpoint that you need to use to display the files within your HTML.
- `AWS_S3_CUSTOM_DOMAIN` is the URL that your application will use to serve your files from. This could point to a CDN or just a custom domain that points to your bucket.
- `AWS_LOCATION` is the file path within your bucket or spaces that your uploaded files will be created. The file path start from the root, so `'files'` would end up being `/files`.
- `AWS_IS_GZIPPED` adds .gzip compression to your files. This will greatly reduce the file size and speed up your delivery and is a no-brainer to use for any web application.
- `AWS_S3_OBJECT_PARAMETERS` allow you to specify custom headers set to each object that you store on S3. In my case I add `CacheControl` to each file to enable browser cache.

Finally you also have to define your normal Django static and media files settings. I use the following settings that are added to my `settings.py` file.

	::python
	STATIC_ROOT = 'static'
	MEDIA_ROOT = 'media'
	STATIC_URL = f"https://{AWS_S3_ENDPOINT_URL}/{STATIC_ROOT}/"
	MEDIA_URL = f"https://{AWS_S3_ENDPOINT_URL}/{MEDIA_ROOT}/"
	
This defines how my files and paths are created and served.

That's it, you should now be able to run `python manage.py collectstatic` and your application should now upload all of your files to your remote S3 storage!

### Should I store both Static and Media files in the cloud?
Personally I recommend you to store both Static and Media files. If you're already paying for cloud storage for one, I'd just do it with the other as well. But if you for some reason are doubting if you should, I recommend you to at least do it for your Media files.

Yes, it is more efficient to serve your static files from a remote storage instead of from your web server, but if you put performance to the site for one second, there are still very good reasons to do it for at least your Media files.

By storing your media files in the cloud you open up the possibilities for scaling your web application the future. Imagine if you upload user files to the web server, what will happen when you try to scale horizontally with multiple web servers?

If the user uploads his profile image to Web Server A on his first request, and his second request sends him to Web Server B, then suddenly the file won't be available any more. If you want to enable horizontal scaling I'd say that **storing your files at a remote storage is a must.**

## Creating Custom Storage Backends
Sometimes you might need to integrate your Django application with cloud storages that isn't supported out of the box with `django-storages`. Last year I was working on a project that was storing a lot of files on Azure Data Lake which unfortunately doesn't use the same way of storing things as Azure Blob Storage does. 

In this case I had to create my own custom storage class for uploaded Media files. Luckily Django have great good documentation of how to [create custom storage classes](https://docs.djangoproject.com/en/2.1/howto/custom-file-storage/).

	::python
	from django.conf import settings
	from django.core.files.storage import Storage

	class CoderbookStorage(Storage):
		def __init__(self, *args, **kwargs):
			"""
			The init method MUST NOT require any args to be set.
			The Storage instance should be able to be instantiated
			without passing in any args. You could use kwargs with 
			default values though.
			
			If you want to read settings you should read them from 
			django.conf.settings.
			"""
			super().__init__(*args, **kwargs)

		def _open(self, name, mode='rb'):
			"""Required method that implements how files are opened/read"""
			raise NotImplementedError("Method not implemented yet.")
		
		def _save(self, name, content):
			"""Required method that implements how files are save/written"""
			raise NotImplementedError("Method not implemented yet.")
			
		def delete(self, name):
			"""Optional method that delete file at filepath"""
			raise NotImplementedError("Method not implemented yet.")
		
		def exists(self, name):
			"""Optional method that return if file exists"""
			raise NotImplementedError("Method not implemented yet.")
		
		def listdir(self, path):
			"""Optional method that return list of files and dirs in path"""
			raise NotImplementedError("Method not implemented yet.")
		
		def size(self, name):
			"""Optional method that return filesize of file"""
			raise NotImplementedError("Method not implemented yet.")
		
		def url(self, name):
			"""Optional method that return the public URL of a file"""
			raise NotImplementedError("Method not implemented yet.")
			
		def path(self, name):
			"""Optional method that return absolute path of file"""
			raise NotImplementedError("Method not implemented yet.")

It is pretty straight forward how you implement a custom storage class. You just implement the required `_open()` and `_save()` methods. Obviously as you can see you can extend your storage class with additional useful methods if needed.

To use your new custom storage class, just set the `DEFAULT_FILE_STORAGE` and `STATICFILES_STORAGE` settings within your `settings.py` file and point them to the python path of your class. E.g. `foobar.storages.CoderbookStorage`.
