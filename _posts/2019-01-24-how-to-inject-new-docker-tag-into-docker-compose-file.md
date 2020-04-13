---
layout: post
title: How to Inject New Docker Tag into Docker Compose File
date: 2019-01-24 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-inject-new-docker-tag-into-docker-compose-file/
---

If you follow best practices then you're tagging each of your Docker images with a unique tag or version whenever it gets updated. These tags might be the git commit hash, a CI/CD Build number or any other value that is usually generated automatically during your build process.

You might be running your containers using Docker Compose and a `docker-compose.yml` file, or maybe you're running things in AWS Elastic Beanstalk with a `Dockerrun.aws.json` file. No matter how you're doing it, you probably have some kind of static file somewhere that contain the images and the tags that you want your application to run. 

Your `docker-compose.yml` file might look like this:

	::yml
	version: '3'
	
	services:
		app:
			image: username/app:d7s8f12
			ports:
				- 80:80

Each time your tag updates, you might want the hash `d7s8f12` to update to the latest tag. How is this achieved? Using `latest` tag is generally considered bad practice because it makes it difficult for you to have a good understanding of what version of your code that is running at any given time. So we want to manually inject our latest tag into our Compose file.

## Use Linux sed Tool To Replace In Place
Out of the box, Linux comes with a bunch of amazing tools that are super useful for these kinds of minor things. One of these tools is `sed` which allows you to do text replacements of strings.

By using `sed` you can automatically update your `docker-compose.yml` file during your deployment process so that it contains the latest tag that you just built and pushed to your Docker Registry. 

Here's an example of how to use `sed`:

	::bash
	sed -E -i'' "s/(.*app:).*/\1$COMMIT/" 'docker-compose.yml' 
	
Let's summarize what we're doing with this command:

- `-E` flag allows us to use extended regular expressions.
- `-i` flag allows us to do in place replacements instead of saving the updated version to a new file. The value after the `-i` flag is the file extension we want to add for the backup of the file. By giving an empty value we don't store any backup and instead save it to the file we read in.
- `"s/(.*app:).*/\1$COMMIT/"` is a regular expression where we add the `$COMMIT` environment variable to the first match, which in this case is the `.*` after the `(.*app:)`. So what this means is that we replace anything behind `app:` with the value of the `$COMMIT` environment variable. In this case `$COMMIT` contains our Docker tag/Commit hash that we want to use.

Note that there's a difference between Linux and Mac OS X when it comes to using the `sed -i` flag. On Mac OS X you have to run it as `sed -i ''` while on Linux you should execute it without a space as `sed -i''`.

When you run this command on the example file above, we should now have replaced our commit hash `d7s8f12` with our latest commit hash stored inside `$COMMIT`.

## Run a Python Script
Another way you can easily update the contents of your `.yml` or `.json` file that defines your containers is by writing a Python script that does it for you. This is more code than just using the `sed` command, but for some situations, this might be the right solution for you. 

To write a Python script that reads in a `.yml` file, update its contents and then save it, you can achieve that with the following script:

	::python
	import os
	import yaml


	if __name__ == "__main__":

		path = os.path.dirname(__file__)

		# Read in compose file
		input_path = "{}{}".format(path, "docker-compose.yml")
		contents = yaml.load(open(input_path).read())

		# Update image string value to the latest tag.
		contents["services"]["app"]["image"] = f"app:{os.environ.get('COMMIT')}"

		# Save file
		output_path = "{}{}".format(path, "outputs/docker-compose.yml")
		with open(output_path, mode="wb") as file:
			file.write(yaml.dump(contents, default_flow_style=False))

You could then run it by just executing `python script.py`.

## Use Environment Variables To Hold Tag
The final and maybe simplest way to make sure that your `docker-compose.yml` file contains your latest tag is to simply define it as an environment variable instead of hard coding it into your file.

However, this requires the system that runs the `docker-compose.yml` file to have access to the tag, which might not always be the option, depending on how your infrastructure and deployment looks like you might not always have the ability to update the Environment Variables on the fly of your server.

The way you could use the environment variable directly in your file would be to rewrite it in the following manner:

	::yml
	version: '3'
	
	services:
		app:
			image: username/app:${COMMIT}
			ports:
				- 80:80

Each time you run `docker-compose up` the system would automatically inject the value of the `$COMMIT` environment variable into the container definition and pull down the correct tag. 

## Summary
Depending on how your system looks like and what tools or values you have access to during deployment, one of these methods should work for you, and allow you to be explicit about which version of the Docker image that you're running, instead of using bad practice and always using the `latest` tag for your container definitions. 

Personally, I prefer using the `sed` tool for all of my deployments. I run all of them on Unix systems so I always have access to `sed`. If I was doing things on Windows I'd probably use the Python script to update my files with the latest tag.

In the end, there is no right or wrong when it comes to these things. It's all about being productive and getting things done, so no matter which manner you choose you should feel comfortable as long as you're getting your deployments done.

Do you have any other methods that you use when it comes to versioning your containers and keeping track on which image that is running on your system? Please share it in the comments below.
