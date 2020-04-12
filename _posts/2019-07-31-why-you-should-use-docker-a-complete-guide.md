---
layout: post
title: Why you should use Docker - A Complete Guide
date: 2019-07-31 00:00:00 +0000
categories: docker
permalink: /@marcus/why-you-should-use-docker-a-complete-guide
---

Getting your docker image built and running is a great achievement by itself, but the world of Docker does not simply stop there. There are still plenty of useful things to learn and dig your teeth into when it comes to Docker, especially when it comes to optimizing your image.

So what is meant by "optimizing" in this context? In general, we talk about optimizing the image from 2 perspectives:

- Optimizing Build Time
- Optimizing Image Size

The first one is useful both for your local development and iteration, but also your CI/CD Pipeline that might build the image on every commit. By properly leveraging cache layers you can make sure that you only have to rebuild as little as possible for each change that is applied.

The second one is useful both for you who are sitting on 128GB Macbook where storage is extremely precious, but also for anyone who wants to make sure that they can provision a new server and pull an image over the internet as quickly as possible. Considering images can be optimized from gigabytes down to megabytes, this type of optimization can have a significant impact when it comes to provisioning servers and pulling images to a machine.

## Optimizing Docker Cache Layers
Docker uses the concept of "Cache Layers" to speed up your builds. This means that for each step in your build, Docker saves the state of the built at that point in time, so that next time you build your image, it can start the build from the step where the change occurred.

This becomes a tradeoff between faster build times and larger storage space. The more cached layers we have, the larger the final image becomes. Optimizing these layers means that we make sure that we cache the frequently changed parts while attempting to reduce the cache layers of the parts that rarely get updated.

### Optimizing Order of Commands in Dockerfile
Imagine that we had the following Dockerfile:

    ::docker
    FROM python:3.7 # Step 1/4
    WORKDIR /app # Step 2/4
    COPY ./src /app # Step 3/4
    RUN pip install -Ur requirements.txt # Step 4/4

This would simply copy our source into our container and install the dependencies. But what happens if our source change and we rebuild our application? The build would have to start from Step 3/4, which means that it would have to reinstall all of our dependencies using `pip` even though they never changed. 

This would greatly slow down our build time. The solution to this would be to separate the `requirements.txt` file from the rest when we copy them into the container.

    ::docker
    FROM python:3.7 # Step 1/4
    WORKDIR /app # Step 2/4
    COPY ./src/requirements.txt /app # Step 3/5
    RUN pip install -Ur requirements.txt # Step 4/5
    COPY ./src /app # Step 5/5

This change would mean that as long as its not our `requirements.txt` file that is changed, we would only need to redo step 5 when we rebuild our image after the source has been modified. This would save us minutes in build time.

### Reducing Number of Cache Layers in Dockerfile
The second way that we can improve the cache layers is to simply reduce them. Theoretically, since we added an additional command in our latest Dockerfile, it means that there is another layer that might have increased our final image. Each command matters.

I stumbled unto a Dockerfile in an open-source package the other day that looked something like this:

    ::docker
    RUN apt-get update
    RUN apt-get -y install git mercurial ca-certificates
    RUN apt-get -y install postgresql postgresql-server-dev-9.3 redis-server
    RUN apt-get -y install elasticsearch openjdk-7-jre
    RUN apt-get -y install python2.7 python-pip python-dev
    RUN apt-get -y install libxml2 libxml2-dev libxslt1-dev
    RUN apt-get -y install npm

Every single one of these commands adds additional Cache Layers to our image without adding much value, the frequency of us wanting to update the system dependencies are extremely low so caching them on this granularity is not very useful.

We could reduce this to a single cache layer by using something that we call "Chaining". 

    ::docker
    RUN apt-get update && apt-get -y install git mercurial ca-certificates \
        postgresql postgresql-server-dev-9.3 redis-server \ 
        elasticsearch openjdk-7-jre python2.7 python-pip \
        python-dev libxml2 libxml2-dev libxslt1-dev npm

As you can see, we still install the same amount of dependencies, but instead of calling `RUN` for each and every one, we chain them into a single command that generates a single cache layer.

You can see this technique being applied if you inspect the Dockerfiles of any of the popular images that exist on Docker Hub such as:

- [Python Alpine](https://github.com/docker-library/python/blob/d2fcc8406cebea404211e808f74fc1090122b4e8/3.8-rc/alpine3.10/Dockerfile).
- [Ubuntu](https://github.com/tianon/docker-brew-ubuntu-core/blob/105329f5da5f205e3d2bcb1f96ce32a472e56239/bionic/Dockerfile).
- [NodeJS](https://raw.githubusercontent.com/nodejs/docker-node/7e47b378c42b03ae6afae704c5bf5b724aae2b92/8/alpine/Dockerfile).

## Optimizing Image Size
The first section regarding optimizing the Cache Layers will have an impact on the  image size, however there are more things related to the image size than just the amount of Cache Layers.

Generally, you should try to only keep the things required to **run your application** within your Docker Image. This means that you do not need things such as Git, Curl, build-tools, gcc and other system packages installed. These things might be required during the build, but not to run the application.

### Use Alpine over Ubuntu Images
The first thing to ask yourself is, "Do I really need a full ubuntu image as a base?". Using Ubuntu might be convenient for you as you get started, because you might be familiar with all the tools. But it's quite rare that you actually need all the tools that ubuntu offers and this is usually something that you can optimize.

In my sample application, when I use the `ubuntu:18.04` image as a base in my build, the final image ends up being 984 MB. That's huge! 

By simply adjusting it to use `alpine` instead of `ubuntu` I am able to reduce the size down to 355 MB, a reduction by ~66%! What's the tradeoff? You might have to install some dependencies that you need manually by using some extra `RUN` commands, and you have to use the  `apk` package manager instead of the more commonly used `apt-get`. It is well worth the trade-off.

Almost all popular images will have an alpine version of it. For example there is a `python:3.7-alpine` over the normal `python:3.7` image. Look it up and change as soon as possible, it's incredibly low hanging fruit.

### Use Multi-Stage Builds
If we continue on the concept of "only store things required for you to run the application", we can continue to optimize our build further even after we have started using an Alpine base image.

Image that we had the following Dockerfile.

    ::docker
    # Inherit from Linux Alpine with Python3.7 installed.
    FROM python:3.7-alpine

    ENV PYTHONUNBUFFERED 1
    WORKDIR /app

    # Install System dependencies
    RUN apk update && \
        apk add --no-cache zlib-dev python-dev build-base

    # Install Python dependencies
    RUN pip install -Ur requirements.txt
    # Copy Source
    COPY ./app.py /app/

We install multiple dependencies using `apk add` that are required for us to be able to use `pip install -Ur requirements.txt` since some of the dependencies need to be built. After we have installed the pip dependencies, we no longer care about the system dependencies we installed earlier.

It would not really help to remove them after the `pip install` step since that would just create a new Cache Layer and the dependencies would still occupy space within our Image. The solution? Multi-Stage Builds.

### How to use Multi-Stage Docker Builds?
A Multi Stage Docker build is a way to reduce your file size even further by disgarding everything that you did in an image except certain artifacts that was produced by the build.

Remember that we have a `FROM` command that goes in the top of our Dockerfile? This command defines where we want to start a new image. So what if we add multiple `FROM` steps in a single Dockerfile? It would only keep the last one in the final output. This means that we can create builds that are "Multiple Stages" or "Multi-Stage".

We could rewrite our previous example into the following:

    # Inherit from Linux Alpine with Python3.7 installed.
    FROM python:3.7-alpine AS builder

    ENV PYTHONUNBUFFERED 1
    WORKDIR /app

    # Install System dependencies
    RUN apk update && \
        apk add --no-cache jpeg-dev zlib-dev \
            python-dev build-base

    # Install Python dependencies
    RUN pip install --prefix=/install -Ur requirements.txt

    # Start a new image.
    FROM python:3.7-alpine

    ENV PYTHONUNBUFFERED 1
    WORKDIR /app

    # Copy the dependencies
    COPY --from=builder /install /install

    # Copy local application into image.
    COPY ./app.py /app/

This is a 2 stage build as you can see separated by the `FROM` steps written in the Dockerfile.

1. Stage 1 install the system dependencies required for us to install our pip dependencies. We use the `--prefix` option to define a unique path where we want pip to install the packages into.
2. Stage 2 starts from a brand new alpine image and instead of installing any system dependencis, we use the `COPY` command to copy the pip packages installed in `/install` from our first `builder` image, into our newly created image.

This helps us reduce our image size from 355 MB down to only 103 MB. Another 71% reduction or about ~90% reduction from the original ubuntu based image that we started off with. 

I bet that you can come up with a bunch of use cases where you might want to use multi stage builds to minimize the final image size. A few examples I can come up with myself would be:

- Install NodeJS and NPM to install node modules and bundle/build your static files into a dist/ folder, and then copy this dist folder into a new image without having to keep NodeJS and NPM installed.
- Reduce the attack surface of your application by making sure there are as few programs installed as possible.
- Start from a Go image and build your Go code into an executable file, and then create a new image from another base without Go installed at all and only copy the executable.

Do you have any other ideas of how to optimize Docker images? Please share them in the comments below.

