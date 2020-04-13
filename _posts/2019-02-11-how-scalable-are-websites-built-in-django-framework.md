---
layout: post
title: How Scalable are Websites Built in Django Framework?
date: 2019-02-11 00:00:00 +0000
categories: docker
permalink: /@marcus/how-scalable-are-websites-built-in-django-framework/
---

Scalability is one of the key concerns that you should take into account when you are planning to build a new application. Your application might start off small, but with time it might grow larger and you definitely want to avoid any kind of rewrite. Because of this, it is important to pick a framework that is easy to get going with, but that is also easy to scale.

So what does "scaling" mean in the context of web applications? Obviously, it means that it can accept more visitors and requests. But it's more to it than that.

- Can progressively scale from a low amount of users to a high amount of users.
- Have modular components that are decoupled and can be replaced if they are determined to be bottlenecks of the application.
- Have long term support for things such as bug fixes or security patches.
- Easily allow new team members to get up to speed with the application as you scale your company and its employees.

As you can see, even if performance is a key part of what we determine to be important for "scaling a website", it is only one of many pieces that we should consider when we are determining if a framework is scalable or not. There might be more efficient solutions, but we have to weight that against the other points and values, such as if the framework is easy to learn, documented and flexible to custom solutions when bottlenecks are identified.

## Existing Applications Prove Scalability
The short answer is that Yes, Django scale exceptionally. We can learn this by simply looking at the existing websites that are running Django right now, by the scale that these websites are running we can simply infer that Django is scalable. Some examples of websites that are running on Django would be:

- Instagram
- Bitbucket
- Quora
- Pinterest
- YouTube
- Disqus
- Spotify

Many of these applications use Client-Server design. This means that the client might be using other technologies such as being built in Swift, NodeJS, Angular or React, but they all use Django as part of their backend to serve the data, process requests and conduct business logic. This means that they use Django to do the heavy lifting of their application. 

These applications differ greatly in their sets of features. Some mostly serve content, others have a huge amount of writes, while some store petabytes of data that their application then serves. By looking at the wide range of types of applications that have been scaled using Django, it gives a strong indication that it has the tools required to scale most types of application. Obviously, this doesn't mean that Django is the most optimal choice in all situations, but it does indicate that if you go down the path of Django, you'll probably do alright when you need to scale.

This gives a simple and direct answer to the question if Django scales. But how does it do in detail? Let's explore piece by piece how Django can be used to scale your application.

## Does Django Scale to Millions of Visitors?
What does "to scale" actually mean? No code out there will be scalable to millions of requests on its own, it will always be depending on the infrastructure that it runs on. So when we talk about scalable applications, we do not only talk about the execution time of the code itself, but we especially want to focus on if it allows us to scale our infrastructure properly that the code is running on. So what are some concrete examples of this?

- Can the app scale horizontally and spread the load across instances?
- Do tools already exist out there that allow us to integrate our application with the infrastructure or services required for us to scale our application?
- If we reach a point or problem that no one else ran into in the past, can we customize the application with our own solution and replace the bottleneck?

All of these points are crucial for us to easily scale our application in the context of performance. We want to make sure that all of these points are checked and fulfilled.

### Can Django Scale Horizontally Using Load Balancers?
There are two main ways to scale an application, you either do it *horizontally* or you do it *vertically*. 

Vertically simple means that you scale your application by upgrading the machine it is running on. You just throw more and more and more resources into it and you hope that it will be enough to support the number of requests that your application is receiving. This usually works quite well at the beginning of your journey to scale your application, but after a while, you will run into multiple limitations with this approach:

- There is a limit of how much resources you can add to a single machine. You can't scale it infinitely.
- It is very difficult to create some kind of auto-scaling infrastructure with this approach. You cannot upgrade or downgrade your machine while the application is running.
- It is more expensive and less efficient. Because of the limitations of being able to easily scale down your application when it has a low load, it means that you will probably overpay for your infrastructure at certain points in time.

As I said, Vertical scaling might be the right choice at the beginning of the lifetime of your application. It has one very significant upside -- It is easy to do. At the beginning of your application, you might not want to complicate your infrastructure with load balancers, stateless web servers etc. Because of this, it might be a simple choice to simply upgrade your server. However, at one point or another, you will run out of resources and you will be forced to start scaling horizontally. If you expect to reach a significant point of scale, it is better to set up your application to scale horizontally from the beginning.

So what then is Horizontal Scaling? Horizontal scaling simply means that you scale by spawning more machines that serve your application side by side of each other, instead of dumping more resources on a single machine. For example, instead of having a single machine that can receive 1000 requests, you might have 10 machines that can receive 100 requests.

The benefit of this is that it is incredibly easy then to add an 11th, 12th and 13th machine whenever they are needed and your application keeps on scaling. There is no upper limit of how much you can scale your application, and in many cases, you can keep using the same technique to scale your application from thousands to millions of visitors. You just spawn additional machines.

All applications can be scaled using the vertical approach, however, if you want to scale your application horizontally, it does put some additional demands on the application itself, and in the context of web frameworks, it requires our Django Framework to provide certain features for us to be able to do this.

The features required to scale our application horizontally are generally features that allow our application to be stateless. Stateless applications mean that they do not keep any state. They don't store any data, images, sessions or files within them. They use third party services for all state, this includes things such as Databases, Memory Cache, Cloud Storage etc.

Django is great when it comes to this, and it definitely gives us the tools needed for us to run our application completely stateless:

- You can replace the default SQLite database (which store data locally) to instead store data on a database that is running on another server instance.
- It supports custom File Storage Backends that allow you to store files on Amazon S3, DigitalOcean Spaces, Azure Blob Storage or any other cloud storage.
- You can customize Sessions to be stored in a database or Key-Value Store (such as Redis) instead of on the file system.
- You can use Cache Backends such as Memcache or Redis to store any cache on another server instead of the file system.

Each one of these features allows us to store our application state **somewhere else**. The key point is not which technology we choose or where we store our state, as long as it's not stored locally with our application.

The reason for this is that if our application stores its state locally, whenever we would spawn a new server to run our application on, it would no longer have access to the same state as the first one. It would no longer be able to access the same files, the same sessions or the same data. We need to store all of these on a third location so that all of our application servers have access to it.

### Django Tools that Allow for Scaling
In the previous section, we proved that Django definitely gives us the capabilities to scale our application horizontally. But do we need to build things from scratch to take advantage of these features and capabilities, or does it already exist tools that will allow us to scale out of the box?

Luckily, this is one of the great benefits when choosing a web framework that is open source and that has a vibrant community. Due to the large open source community of Django, most of the tools that you need to scale your application already exist out there.

A few examples of these tools would be:

- [Django Storages](https://github.com/jschneier/django-storages)
    - Amazon Web Services (AWS) S3
    - DigitalOcean Spaces
    - Azure Blob Storage
    - Google Cloud Storage
- Memcache and Redis Cache Backends (Part of Django)
- PostgreSQL, MySQL Database Backends (Part of Django)
    - [Microsoft SQL Database Backend](https://django-mssql.readthedocs.io/en/latest/)
- Redis and Database Session Backends (Part of Django)

All of these tools means that you can be ready to set up your application for statelessness and scale out of the box. If you require support for other services that are not supported by these tools, it is important to note that Django is pluggable and allow the programmer to replace most pieces with their own "Backend" class. This means that you can often replace the existing built-in features with a custom backend for the service you want to add support for. I recently did this to store files on Azure Data Lake and it was very simple and straight forward.

On top of this, the Django Community has developed multiple tools that allow us to find bottlenecks, debug and improve the performance of our application. 

Some of these tools are:

- [Django Debug Toolbar](https://github.com/jazzband/django-debug-toolbar/)


### Replace Bottleneck With Custom Solution with Django
Luckily for the world, all types of applications haven't been built yet. New unique applications with new demands are always popping up and pushing the industry forward. This means that even though we have huge applications such as Instagram, Disqus or Bitbucket using Django in scale, it does not necessarily mean that your unique application with its own needs will not run into some unique problem.

In today's world of Blockchains, Streaming, and Search, application developers might find new bottlenecks that others haven't run into yet, and when this happens it is very important that the framework that the application is built upon, allows the programmer to solve the bottleneck on their own, by replacing the failing piece with a custom solution that fit the application's needs. This means that the framework must be "pluggable" and modular. If you're not satisfied with the Database, Cache, Session, File or any other provider/integration, you must be able to replace it with your own.

Django is a fairly opinionated Framework with "batteries included". This means that Django comes with a lot of features and tools out of the box, and it has some kind of expectations on the underlying infrastructure that you plan to use. For example, Django has its ORM which expects you to use a SQL Database such as MySQL or PostgreSQL. If you want to use a Document Database such as MongoDB, Django might not be the right tool for you. This means that the pluggability of Django might be less than something like Flask or Express which simply let your plugin any tools you want.

With that said, this does not mean that Django is not pluggable at all. There has been a lot of effort invested in making Django pluggable and allow developers to extend it in their own ways. Instagram is a great example, they used a very custom implementation of Django which allowed them to scale to 100's of millions of users. Django has extensive configuration possibilities with its `settings.py` file that allows you as the developer to configure most parts of the framework.

A few examples of what settings you can set to plug in your own custom solutions into Django:

- Authentication Backend
- Session Storage Backend
- Cache Backend
- Database Backend
- Static Files Backend
- Media Files Backend
- Logging Handlers

On top of this, you can also create your own Middlewares that allow you to hook into the HTTP Request/Response cycle.

Django is definitely "pluggable", and if you discover a bottleneck you will probably be able to replace it with your own custom solution in a fairly straight forward manner. With that said, Django is still opinionated which means that it might limit the options you have, or at least bring some side-effects when you go outside the box it has set in its mind.

### Conclusion on Django Performance Scaling
Django is definitely an extremely scalable and well thought out framework. It will allow you to scale your application horizontally and be able to support hundreds of millions of requests as we have seen in the cases of Instagram, Bitbucket, Disqus and more.

The opinionated design of Django allows us for fast development, and it allows Django to give us the tools needed to build a great application out of the box. The price we pay for this is some additional constraints in flexibility and options. This might mean that your options are fairly limited whenever you run into bottlenecks and problems, it is important to take note of this and be prepared for that if you are building a very unique application that explores new territory.

## Django Support for Security Patches and Bug Fixes
On top of making sure that the Django Framework is scalable from a performance perspective, we also want to make sure that it is scalable in the sense of time. Will the framework not only be a good choice today but also 3 years from now? Will it get continuous support and updates to solve security problems or bugs?

As you can see from [Django's Release Schedule](https://www.djangoproject.com/download/), each release has a period where it gets updated with minor patches but then it goes into an LTS period (Long Term Support) where it continues receiving security updates for a certain period of time.

This period might range from somewhere between 2-3 years per release, this means that even if you don't update to a new major release, you can feel confident that the release you are running will be secure even 3 years from now.

Django has a very extensive and detailed [Security Policy](https://docs.djangoproject.com/en/dev/internals/security/) where they describe how they release new security patches and inform any website owners of any vulnerabilities discovered on the release that they are running their application on.

The conclusion of all this is that if you choose Django as the foundation of your new application, you can feel confident that it will scale well into the future with frequent updates, fixes and security patches even if you decide not to upgrade to other major releases.

## Does Django Allow To Scale With New Team Members?
Initially, this might sound like a weird question. What do I mean with if it scales with new team members? Doesn't all code do that?

Well, once I was working at a company who like so many other companies had decided to create their own proprietary web framework written in PHP. The framework was losely following the MVC principle and pattern, and due to this, you could infer some things from the start. But that was about the end of it.

Everything else was unique, proprietary and far from what you might see from other frameworks. Honestly, it was pure garbage. On top of this, there was no documentation, no training material, and no open source community or tags on StackOverflow that you could query for answers. 

Every time a new programmer was added to the team, there was a long and painful onboarding period where the programmer had to navigate around all the crooks and bends of the code base until they could finally understand how things related to each other, and to start being productive. 

This is an example of a code base and a framework that does not scale well with additional team members.

[Uber scaled from 200 engineers to 2000 engineers in 18 months](http://highscalability.com/blog/2016/10/12/lessons-learned-from-scaling-uber-to-2000-engineers-1000-ser.html). Imagine that being done on some proprietary solution without documentation and training material that help each programmer with the onboarding process. That would be painful. 

This is where the great value of Open Source comes into the picture and discussion of scalability. By using a framework such as Django as the foundation of your application, you automatically make it easy to scale your team by either employing any of the tens of thousands of Django developers out there or by simply hiring someone and training them with the official [Django Documentation](https://docs.djangoproject.com/).

This means that you can onboard people in a fraction of the time compared to the alternative, and you can waste less money on the unproductive onboarding period and get your team to full productivity much faster.

## Conclusion, is Django Scalable?
In this article, we covered multiple perspectives on scalability.

- Performance
- Security and Patches
- Team

Django is scalable in the context of each one of these unique perspectives and it will not only allow you to scale your application to thousands of servers in the cloud by leveraging horizontal scaling, but it will also allow you to scale with time and with new team members.

This should give you the confidence you need to pick this framework as the foundation of your new application and calm any worries you might have of what will happen when you reach success at scale.
