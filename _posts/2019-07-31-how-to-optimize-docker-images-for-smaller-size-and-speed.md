---
layout: post
title: How to Optimize Docker Images for Smaller Size?
date: 2019-07-31 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-optimize-docker-images-for-smaller-size-and-speed/
---

Docker is one of those rare technologies that completely rock your world when you understand the benefits and usages of it. It is definitely the number one technology that I appreciate getting into the last few years, and these days I use it in every single Software Engineering project that I get into.

At first glance, Docker might seem a bit overwhelming because it seems like there is so much to it. You will quickly discover that it is made up of products and terms such as:

- Docker
- Docker Compose
- Docker Swarm
- Docker Hub
- Docker Machine
- Docker Engine

Don't worry, you don't need to do a deep dive in every term and concept, the main things you need to know to get the full usage out of Docker is "Docker" and "Docker Compose".

## Example Docker Usage Case - MemeGenerator
To illustrate the reason why you can benefit a lot from using Docker as a part of your engineering toolbox, I will give you a sample case.

Imagine that we want to build an application that we call "MemeGenerator" that simply takes an image and apply some kind of text to it.

![](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/docker_meme.jpg)

The properties of this application would be:

Features:

- Add text to image.

Technologies Used:

- Python.
- Pillow PIP Package.

Usage:

- Install dependencies.
- Run Application
- Choose Image and write text, and download the resulting meme image.

Sounds simple right? So imagine that Developer A has created the application and he send it to Developer B who attempts to run it. There is a chance that he will be met with the following screen as he type `pip install -Ur requirements.txt`:

![](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/docker_crash.png)

Developer A will most likely have the following response:

![](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/docker_it-works.png)

## There are more Dependencies than Language Packages.
The issue that Developer B experienced above was that he was unable to build the `Pillow` package on his machine because he was missing some system dependencies. This is an incredibly common issue that you will experience as a developer either on your own machine, or on the server where you try to deploy your application. 

In reality, there are more types of dependencies than just the common language packages for package managers such as `npm` or `pip`.

For example:
- OS Differences (Mac, Windows, Linux).
- File System Differences.
- System Packages.
- Interpreter Version (e.g. Python 2.7 vs Python 3.7).
- Environment Variables. 

All of these things will have an impact of how your application will run on the machine where you deploy it. Wouldn't it be wonderful if there was a way to package all these things together, to make sure that wherever we run our application, it is always executed in well defined environments? The solution is Docker.

## What is Docker?
Docker is a tool that allow us to package software into lightweight, executable images that contain not only the application itself, but also the full system. You can then execute these images and create a running version of the, which we call a "container". 

The Docker Image will contain things such as:

- OS Base, for example, Ubuntu.
	- This solves file system differences.
- System Packages.
- Interpreter, e.g. Python or NodeJS.
- Environment Variables.

This concept might sound similar to a "Virtual Machine", and yes there are some similarities, but it is not the same thing.

![](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/docker_compare.png)

Unlike Virtual Machines, a Docker Image is **lightweight** and can be executed and turned into a running container in **seconds**. This makes it incredibly useful for local development, but also for situations when you want to add or remove containers, for example in an auto-scaling situation.

On top of that, a Virtual Machine might require gigabytes of storage while a Docker Image can be as light as a few megabytes. 

The reason why these benefits are possible is because a Docker Container does not require an operating system for itself. It can run on the Host OS. This is the magic part of Docker that is possible because of the Docker Engine that must be installed on each environment where you want to run a Docker Container. It is the only real system dependency that cannot be bundled with the image itself.

### How to Define and Build a Docker Image
The Docker Image is built by the definitions that you have written in what is called a `Dockerfile`. This file describes step by step what the Docker Builder should do as it is building your image. 

```dockerfile
# Inherits from base image.
FROM python:3.7
ENV PYTHONUNBUFFERED 1
WORKDIR /app
# Install a system dependency.
RUN apt-get update && apt-get install -y foo
# Copy our source code into the container's work directory.
COPY ./src /app
```

As you can see from the example above, the syntax for writing a Dockerfile is incredibly simple and easy to understand. There is no need for complex bash scripts that often can be seen in other places.

This definition is just an example, but it shows you have to do basic things such as:

- We define which base image we want to use, in this case, we use `python:3.7` which is a Ubuntu installation with the common python system dependencies included for running Python 3.7.
- We set an environment variable within the image.
- We define the Work Directory. This is the target directory of all our commands.
- We run a shell command, in this case, it installs a `foo` dependency using `apt-get`.
- We copy our local `./src` folder into the image's `/app`  folder.

The resulting image will contain our source code and the system dependencies included.

If you want to try out running a container yourself, you could just use something like `docker run -ti python:3.7 bash` to get a bash prompt into the `python:3.7` container. Here you can quickly discover that you have a full Ubuntu Linux container running with all the tools you would expect to be available. It's amazing!

### Share Images using Docker Hub
In the previous example, we were able to inherit an image called `python:3.7`. Where is this image actually coming from?

If you are familiar with Git and GitHub you will have an easy time understanding the concept of how Docker Images can be shared. 

In Docker, we use something that we call a "Docker Registry" to push and pull images from. This is a centralized location where all of our team members can access the latest versions of our application's images. This is very similar to the concept of a "Git Repository" which also is a centralized location where team members can push and pull the source code.

So in the case of Docker, when we run commands such as `docker run -ti python:3.7 bash` or define `FROM python:3.7` in our Dockerfile, what we are doing is telling Docker to get the "python" image with tag "3.7" from the default Registry, which in this case is [Docker Hub](https://hub.docker.com/_/python).

You can use Docker Hub as a Registry for public images for free. The free usage when it comes to Private images has some limitations at this point, and depending on your needs you might need to upgrade to a paid plan.

## Summary of Docker

Let's recap before we continue with additional topics related to Docker.

- We build Docker Images that not only contains our source code, but also contains its dependencies, its system dependencies, and the OS itself. It encapsulates **everything** that we need to run the application.
- We store our builds in a centralized registry that the whole team can pull from. This registry can host both public and private images similar to a Git Repository.
- Executing a Docker Image turns it into a Docker Container. Its boot time is almost instant.
- You can run your image **anywhere** where Docker Engine is installed. Both for development on your local machine, or to run your application in production.

The result of this is that from now on, you will have no discrepancy between environments when you run your application. You can be confident that it will be executing **exactly** the same each time you run it, no matter where you run it from.

## Service Dependencies
Docker Images takes care of bundling all the dependencies that are required for you to run the application itself. But what about all the services that your application might need to communicate with to be able to function correctly?

For example, a web application might depend on a PostgreSQL server, or your data application might depend on a Hadoop File System. These are what we call "Service Dependencies" that the code itself might not depend on, but the application still requires to function properly.

A few examples of these are:

- PostgreSQL Database.
- RabbitMQ Message Broker.
- Redis Cache.
- Hadoop File System
- Hive
- Nginx Web Server
- MemCache

You might not want to bundle all of these things within your Docker Image (even if in many cases, in theory, you could) because when you run your application in production, you want these things to run on separate machines. You view each of them as a separate application from the others.

The solution to this is to use what we call Docker Compose, that allows you to compose multiple containers and images together with a single executable command.

## Why use Docker Compose?
Docker Compose solves the issue regarding Service Dependencies described in the section above. It allows you to "Compose" multiple containers to run side by side on the same network, which allows them to seamlessly communicate with each other.

I'm sure that most developers have had the case where they pull down some code that they attempt to run on their local machine and quickly realize that the code depends on services such as Nginx, PostgreSQL or MySQL to run correctly. The developer will then be forced to install these services on their local machines which introduce a new flaky dependency.

When you install these things manually it might introduce differences such as:

- Differences in actual technologies. Commonly, some developers choose to use tools like SQLite on their local machines vs MySQL on the production server.
- Differences in version.
- Differences in the configuration.

By having a clear definition of all the services required to run side by side your application, it makes it incredibly easy to spin up an exact mirror of your production environment on your local machine.

Decreasing the discrepancies between environments has a huge impact on reducing potential bugs and issues that in other cases you might only discover after deployment.

### Docker Compose Definition YAML File
So how do you define which services that you want Docker Compose to create? It's done using a simple `docker-compose.yaml` file.

```yaml
version: 3
services:
    db:
        image: postgres:9.6
        restart: always
        ports:
            - "5432:5432"

    app:
        image: meme:latest
        restart: always
        depends_on:
            - db
```

You can then execute this Docker Compose file using `docker-compose up` in the directory where the file is located. It will automatically pull down the images and execute them on the same network, which allows both of the containers to communicate with each other.

The syntax is once again very simple and easy to understand:

- We define which Docker Compose syntax version we use.
- We define a list of services to run.
- Each service can have multiple different properties such as the image name, the port mapping to the host OS, the restart policies and which services that a service depends on (to control boot order).

### Summary of Docker Compose
Docker Compose is a great addition to add to your toolbox as you start learning more about Docker. As you can see, it allows you to run multiple images together with a single definition and a single `up` command.

The benefits are plenty:

- No/Extremely Low discrepancy between environments.
    - Developers can run "Production Infrastructure" on their local machines.
    - Continuous Integration Pipelines can run the test suite on "Production Infrastructure" to increase the reliability of tests.
- Docker Compose is ready to be used in Production to run your real application. It has restart policies that make sure that containers are automatically restarted if they crash, and you can run Docker Compose as a daemon using the `-d` flag.
- New Developers can get the application up and running with a single command after pulling down the source code. This greatly speeds up onboarding of your project.

I would recommend you to use Docker Compose in all types of projects where you have any kind of service dependency. It is such an amazing tool and it makes it so easy to run an application and share your work with others.