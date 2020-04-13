---
layout: post
title: Generate Thumbnails Automatically in Django with sorl-thumbnail
date: 2019-02-05 00:00:00 +0000
categories: docker
permalink: /@marcus/generate-thumbnails-automatically-in-django-with-sorl-thumbnail/
---

Generating thumbnails for your media content that is in the correct size, and optimized for the web by stripping any additional metadata away from them, is one of the main things that you will be recommended to do if you want to improve your websites load speed.

This can, however, be a quite tedious job, it might require you to install special software on your computer, and it might duplicate the work needed for adding media content to your posts. In the worst case scenario, it could either greatly slow down your website, or discourage the authors to add content to the articles that might be important to the users, just because they are too lazy to optimize it properly.

The way that we could solve this issue is to automatically generate thumbnails on our website whenever new media content is added. This would remove any additional complexity required on the authors part, while also making sure that things are perfectly optimized for every single image throughout our website. Sounds like the best of two worlds right?

## How to Auto Generate Thumbnails for Uploaded Images?
There are three approaches that you can take as a software engineer to develop a feature that would automatically generate thumbnails for images that have been uploaded on your website.

1. Generate a thumbnail for each required format whenever the file is uploaded.
2. Convert the size of an image on the fly whenever an image is requested.
3. Generate a thumbnail file and store it on disk whenever the thumbnail is requested.

### 1. Generate Thumbnail When Image is Uploaded
The first example could be a nice solution if you already know exactly which formats that will be required, and you don't have any plans to change them. You can then predefine which sizes you need and then just generate them from the start whenever the user uploads them.

There are a few downsides to this method:

- You would need a separate solution for images that aren't uploaded. For example, if a user login with Facebook and you want to display the user's profile picture. This link would be to Facebook's Graph API and it would not go through the same flow as when someone attaches or uploads a file to an Article. 
- If you change your website's design in a way that alters the thumbnail format required, you also need to somehow trigger regeneration of all images so that they are stored in the new optimal format.

### 2. Convert Image Size On The Fly On Request
Another option is to allow users to specify GET parameters in the URL to the image of the size needed, and then automatically convert the image on the fly whenever its served.

For example, you could create an URL that would be `/profile` that then accept additional parameters such as `?width=300&height=300` that would then fetch the image, convert it and serve it in the correct size.

I've seen this approach being used a few times and I generally dislike it for multiple reasons:

- This requires your web server to serve your image requests instead of them going directly for CDN or S3 storage.
- It's slow and put additional demands on your server requirements.
- Even if you cache the image, the request still must go to the web server so that it can check the cache.

I would say that the only benefit would be if you have a public API and you have no idea which sizes that your users might require for the images requested. This approach would then allow users to define any size to fetch the images in.

### 3. Generate Thumbnail File When Requested
The third and final option is similar to the second option but more efficient. Instead of serving the file from the web server and converting it on the fly each time, you keep track on whenever a template needs to serve the template and then generate a file on disk for the size required. 

You then store the file path of the original file and the thumbnail in a Key-Value Store and then reuse the thumbnail each time it is being requested in a template of your application.

For example, let's say we have a profile image that is uploaded in the size of 600x600 pixels. In some places of our application's templates we might use it as 50x50 and in other places, we might use it as 300x300. Instead of generating these thumbnails ahead of time like in option 1, we generate them the first time a template attempts to include it, and then after that initial request, each new request will reuse the generated thumbnail, as long as the size hasn't changed.

If the file dimension required in the template updates, we ignore the previously generated file and generate a new one. This means that if our designers iterate on our design, we can generate new files automatically whenever they are requested in their new format.

The downsides of this approach are the following:

- If you have an empty cache/Key-Value store and you receive a lot of traffic, it might require a lot of performance from your server during the initial generation of the files. This can be solved by "warming up" the cache ahead of time.
- Unless you clean up files when you change the required file dimensions, you might end up with a lot of old unused files that take up storage space.

In general, I still think this is the best approach with the right amount of balance between performance and flexibility because it offers us the following benefits:

- Flexible and can allow new sizes of thumbnails very easily.
- We still can serve the thumbnails directly from the storage or CDN since the URL to the thumbnail don't need to be pointed to our web application as in Option 2. The server will replace the URL with the original full-size file to the URL of our thumbnail before it's served to the client.

Django has a great package named [sorl-thumbnail](https://github.com/jazzband/sorl-thumbnail) that can help us with this approach. I've used it for multiple projects in production and it has worked really well.

## Why you should use sorl-thumbnail with Django
The sorl-thumbnail package is a great module and it offers us multiple features and benefits that will greatly improve our load speed such as:

- Built-in support for Django storage backends for easy integration with e.g. Amazon S3 or DigitalOcean Spaces.
- Pluggable Key-Value Store. You could either store your thumbnail references in the database or choose more optional choices such as Redis or DynamoDB.
- Pluggable support for engines that generate the images such as Pillow, ImageMagick, Wand etc.
- Alternative resolutions for thumbnails. E.g. you might normally want it as 150x150 but for retina displays, you might want to be served in 2x.
- Flexible syntax. It does not generate a complete img tag that makes it complicated for you to add custom attributes or classes. Instead, it allows you to construct the HTML yourself and insert any values needed for the thumbnail in your own manner.

### Installing sorl-thumbnail
The installation process of the package is incredibly easy, but it does require a few dependencies that need to be installed before you can start using it.

First of all, you need to have some kind of image engine installed on your system so that you can interact and generate images. If you are using Django's `ImageField`, you probably already have `Pillow` installed. If not you need to follow the following steps (Ubuntu):

	::bash
	sudo apt-get install libjpeg62 libjpeg62-dev zlib1g-dev
   	# There might be a more recent version 
   	# when you read this article.
	pip install Pillow>=5.4.0

If you don't want to use Pillow, you can choose any of the other supported engines such as:

- ImageMagick
- Wand
- pgmagick

After you have installed any dependencies, you can install the sorl-thumbnail python package using pip.

	::bash
	# There might be a more recent version 
	# when you read this article.
	pip install sorl-thumbnail>=12.5.0

Finally, you need to add it to your settings `INSTALLED_APPS` list 

	::python
	INSTALLED_APPS = [
		...
		'sorl.thumbnail',
	]

That's it! At this point, you should be able to start using the sorl-thumbnail package in your application.

### Using sorl-thumbnail In Your Django Project
The way you generate thumbnails using this package is by adding special template tags in your template files that allow you to replace existing image references, with newly generated thumbnail references instead.

For example, if our user object has a `profile` property, we tell `sorl-thumbnail` to replace this reference with a new object that contains data of the generated thumbnail instead.

	::html
    {% raw %}
	{% load thumbnail %}
	{% thumbnail user.get_avatar_url "70x70" crop="center" as im %}
            <img src="{{im.url}}" height="{{im.height}}" width="{{im.width}}">
	{% endthumbnail %}
    {% endraw %}

As you can see in the example above, our original file reference comes from the `user.get_avatar_url` function call. In this case, we replace that with an `im` object that contains the newly generated thumbnail in 70x70 format.

When Django loads this template, it will automatically generate the files needed and replace any references to the original file in the final HTML that is given to the user. This means that the URL's that the user receives will point directly to the thumbnails.

#### Use Retina or Alternative Resolutions
What if we want to display our image as 70x70, but some devices that use high-resolution displays might want to have a higher DPI (dots per inch) of the image, to avoid it appearing blurry and pixelated.

We can achieve this by specifying "Alternative Resolutions" for our thumbnails. To do this we need to do two things.

First, we need to specify which additional resolutions we want to generate thumbnails for. This is done by adding the following option to your settings file.

	::python
	THUMBNAIL_ALTERNATIVE_RESOLUTIONS = [2, ]

Note that you can provide a list of values, 2 in this case, means that we want to generate thumbnails 2x the size of the specified value. This means that if we want to display our thumbnail as 70x70, we also generate a 140x140 version of it.

The second thing we need to do to serve our 2x images, is to use the resolution filter within our template whenever we want to use an alternative resolution.

This filter is available as long as you have loaded the thumbnail template tags using the `{% raw %}{% load thumbnail %}{% endraw %}` syntax. 

The final look of our template code that use the resolution filter syntax to load the 2x alternative resolution would be the following:

	::html
    {% raw %}
	{% load thumbnail %}
   	{% thumbnail user.get_avatar_url "70x70" crop="center" as im %}
           	<img src="{{im.url|resolution:'2x'}}" height="{{im.height}}" width="{{im.width}}">
	{% endthumbnail %}
    {% endraw %}

### Configuration and Common Problems
It's incredibly easy to get going with the sorl-thumbnail package, but sometimes you might want to add some kind of custom configuration to alter the default behavior.

You can get a lot of useful information from the [sorl-thumbnail documentation](https://sorl-thumbnail.readthedocs.io/en/latest/reference/settings.html) that reference most of the settings available. 

There you can do things such as changing the Key-Value Store backend, enabling DEBUG mode or change the quality of the thumbnails generated to a higher or lower value which will alter the final file size of the image.

If you run into any issues with the module, the main thing I'd recommend you to do is to enable logging to improve the ease of debugging the issue. This can easily be done by adding the following to your settings file:

	::python
	LOGGING = {
   		'version': 1,
		'disable_existing_loggers': False,
   		'formatters': {
			'simple': {
				'format': '{levelname} {asctime} {module} - {message}',
    	       		'style': '{'
			}
   		},
		'handlers': {
       		'stream': {
           			'level': 'DEBUG',
           			'class': 'logging.StreamHandler',
           			'formatter': 'simple',
       		}
		},
   		'loggers': {
       		'sorl.thumbnail': {
           			'handlers': ['stream', ],
           			'level': 'DEBUG',
           			'propagate': True
       		}
    		}
	}

This would then output any log entries of DEBUG level or higher using the StreamHandler.

A second thing to note is that not all setting values are documented in the documentation that I linked above. For example, I had an issue where I wanted to generate thumbnails from Facebook's Graph API. This API uses GET parameters in the URL to define the options of the profile picture.

For some reason, the sorl-thumbnail package was ignoring all the GET parameters provided in the URL to the image. When I enabled logging, it appeared that it was fetching the correct URL's with the correct GET parameters, but apparently, when I looked through the source code of the library, it was using a setting to strip away and ignore any GET parameters of any image url.

This particular setting could be controlled by setting the following options.

	::python
	THUMBNAIL_REMOVE_URL_ARGS = False

If you encounter any other issues related to settings that might not be documented, I suggest that you contribute to the open source package by creating a pull request that adds any missing documentation.
