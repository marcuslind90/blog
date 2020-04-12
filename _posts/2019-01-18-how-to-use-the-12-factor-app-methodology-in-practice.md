---
layout: post
title: How to use The 12 Factor App Methodology in Practice
date: 2019-01-18 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-use-the-12-factor-app-methodology-in-practice
---

How do you build an application that is easy to deploy to the cloud, easy to scale, secure and a breeze to work with as a developer? It's a question that should be in our heads for every new project we work on, since we should always aspire to produce high quality work that can take a business to the next level. 

Wouldn't it be amazing if there was a methodology out there with strict chapters or guidelines and you could use for every project in a repeatable fashion, that would allow you to achieve these things, and to take the quality of your work to the next level?

[The 12 Factor App](https://12factor.net/) is a methodology written by the team at [Heroku](https://www.heroku.com/) which aims to give software engineers the guidelines needed to not only deploy their projects on the Heroku platform, but also to be able to deploy their projects on any cloud platform out there.

It lays out 12 different rules that you should follow during the development of your application. Some of these rules feel obvious at first glance, but when you combine them all together it makes sure that your application becomes a great bundle of code that is great to work with and great to deploy in production.

Unfortunately, the guide itself does not give much concrete examples of how to achieve some of these things. Today I hope to take you along and show you how you can achieve all these guidelines in reality.

## I. Codebase
[Codebase](https://12factor.net/codebase). The first step of the 12 Factor App is the codebase itself. There's a few core things that we can learn:

- Your codebase should always be under version control such as [Git](https://git-scm.com/). 
- Your codebase is always on a 1-to-1 correlation with the application. What this means is that a codebase only includes a single application, and an application only has a single codebase.

The days where you FTP into a server and manually upload changes or edit files live on production are all gone, if you're still doing this it's something that you should look into changing as soon as possible.

By using version control, not only does it give you the ability to rewind and go back to changes that would in other cases be lost, but it also completely changes your work flow and prevents you from doing bad practices such as live editing files. Instead you work locally, you push to a repository, and you deploy. The code will always be in sync with the repository and you will never have different versions of your codebase laying around.

The second point regarding the 1-to-1 correlation with the application sounds a bit vague. What does it really mean? 

Well imagine if you have a Staging Environment and a Production Environment. It is important that both of these environment are running the same codebase/repository. Perhaps they are running on different versions or branch -- which is fine -- but they are still running on the same codebase. 

Maybe it sounds obvious to do it that way, but some people might create different repositories by environment, or perhaps they don't keep their code in version control with a centralized repository at all, so changes to one codebase cannot be tracked and replicated in the other.

To get down to it, this rule is saying that you should use version control such as Git, and you should use branches to distinguish between staging, development, production etc.

Finally, this rule also mentions that a repository should always contain a single application. This basically means that you should stay away from a monolithic repository that contains all your applications within your company. Personally I prefer to follow this rule, but many companies don't and still seem to do well. In reality I feel that this advice is subjective and its difficult to give very strict guidelines about it.

## II. Dependencies
[Dependencies](https://12factor.net/dependencies). The second step of the 12 Factor App is regarding your application's dependencies.

These days most programming languages offers dependency managers that allow you to explicitly define which dependencies your application depend on to work properly. I still remember the days before PHP's Composer (which is its current dependency manager) and how difficult it was to keep track on which versions and what software that you relied on.

By being very explicit about your dependencies, you make it incredibly easy for the next developer who comes along and needs to setup the code base. Ideally they should be able to simply run a single command to pull down any dependency they need to get the application up and running.

An additional point is that its not enough to just define which dependencies you need, but you also must be very explicit about which version you depend on. I've worked on projects in the past where programmers didn't define the version of the package and from one day to another, our build process just stopped working. These things can be very difficult to debug when things stop working from one day to the next, and you can't understand what changes were introduced.

So for you in your own project, follow the following rules:
- Use a package manager such as Pyton's `pip`, Javascript's `npm` or Ruby's `gem`.
- Be explicit about versions. For example, don't just define `django` in a `pip` file, write `django>=2.1.0`.

## III. Config
[Config](https://12factor.net/config). The third step of the 12 Factor app is regarding configuration credentials and secrets, and how you can protect them.

What the 12 Factor App means about "config" might be a bit confusing at first. They're not talking about all of your configuration files, but they are explicitly talking about the configuration that might change between environments. For example, you might have different Database credentials on your Development environment than on your Production environment.

Some developers manage this by having multiple configuration files that gets loaded depending on which environment you're on, and each configuration file contains the credentials and secret that is relevant to that specific environment.

But ask yourself. Could your application be made open source right now, without exposing any credentials or secrets to the public? If you're storing your secrets within your code, it means that anyone with access to the code would have access to your complete infrastructure. Ouch, right?

The solution to this is the define each configuration value that might change between environments or that should be secret, as Environment variables on the system.

Let's use python as an example of what you should and shouldn't do.

	::python
	# Bad
	DB_HOST = "db.domain.tld:5432"
	DB_PASSWORD = "p4$$w0rd"
	
	# Good
	DB_HOST = os.environ.get('DB_HOST')
	DB_PASSWORD = os.environ.get('DB_PASSWORD', None)
	
Not only does this allow you to protect the credentials from prying eyes, but it also makes it incredibly easy for you to change your credentials without having to rebuild and redeploy your code. You could for example automatically change passwords to some of your services on a certain schedule and just update the Environment Variable when you do so, or if one of your services goes down, you can simply point it to a new host in an instant.

## IV. Backing services
[Backing services](https://12factor.net/backing-services). Backing services means any type of service that your application depends on for its normal operation. This could be your MySQL Database, RabbitMQ Message Queue, SMTP server, S3 Storage etc. 

What the forth step of the 12 Factor App says, is that you should keep your code very loosely coupled from these services, and they should be able to unplug and replace without any changes within your code. 

For example, if you're running a website that store its assets on AWS S3, and you then notice that DigitalOcean Spaces S3 offers the same functionality for a cheaper price, you should be able to replace your existing service with the new one, without having to do changes to your code. Your code shouldn't be tightly coupled to the services and depend on specific sources. 

The previous step III. is a great way to help you simplify this. Don't hardcode your credentials and hostnames into your code, instead refer to them by configurations and environment variables. This makes it incredibly simple to replace a service with another.

## V. Build, release, run
[Build, release, run](https://12factor.net/build-release-run). The fifth step from the 12 Factor App is all about preparing your application so that its easy to run and execute.

First of all, you need to separate the run process from the build process. What this means is that you don't want to just deploy your complete repository on your server and then live on the server start downloading dependencies and build files. Instead you want to prepare all of this before you release and run, so that it can be executed instantly whenever its deployed.

My favorite tool for this is [Docker](https://www.docker.com/). Docker allows you to build an image of your application which will contain all of its dependencies and bundles, and then you can execute and run it with a simple command in a second or two.

You then only release the image of your application, not the complete repository. This means that as soon as you spin up a new server and your code is deployed onto it, it is ready to run.

On top of this, by bundling your application into an image, it will make rollbacks incredibly easy if you also version your image by tagging it with your commit ID, a version number or a timestamp. You can simply deploy the previous image and run it instantly to get back the previous state of your application. 

By separating the build process from the run process it will also change your workflow. It means that you will never be able to just change a file while its running, because any changes to code will require a new release, and a new release require a new build.

By forcing each developer to follow this process, you can make sure that any change is pushed into version control, and that each code change has gone through your build process which might include automatic testing, linting and code review.

## VI. Processes
[Processes](https://12factor.net/processes). The sixth step of the 12 Factor App is about running your application as stateless processes. 

So what is stateless? Well its the opposite of stateful. A stateful application is something that store the state of itself, for example a MySQL Database is a stateful process. It stores the data and if you restart it, it will still have the same data available.

A stateless process is something that never stores its own state, it only executes and process information. This is how we want to run our application because it makes scaling incredibly easy since you can then run multiple processes of your application and no matter which one the web request hits, it will be treated exactly the same.

To know if your own application is stateful or stateless. Ask yourself this, if you deployed your application on a new server. Would it behave exactly the same as your current one? Or would things break and be missing. 

What if you logged in to Web Server A, but the next request hit Web Server B. Would Web Server B know that a session was created on Web Server A?

What if you uploaded a profile picture on Web Server A, but the next request hit Web Server B. Would Web Server B have access to that image that was uploaded on Web Server A?

Unfortunately most web applications are not stateless. They might store uploaded images, sessions or expect that something exist that was created in a previous request. If this is the case it makes it very messy and tricky to spin up additional instances of your application and load balance the traffic between them.

The solution to this is to store all state on backing services. Use databases or S3 storage that keep track on the state, and then let all of your processes read the state from these backing services.

## VII. Port binding
[Port binding](https://12factor.net/port-binding). The seventh step of the 12 Factor App is regarding how you expose your application on your server.

A 12 Factor App is self contained and does not rely on any kind of outside tools to exist on the server to execute itself. For example, a Java application might rely on Tomcat to exist on the server to execute it, or a PHP application might expect Apache to execute it.

As we've talked on previous sections, we should explicitly define all dependencies and bundle them within our application. We should be able to execute and run the application as it is. This means that when we run the application it should be ready to listen for incoming HTTP requests and be exposed on some port so that outsiders can interact with it.

An example of this would be Python using `gunicorn` or NodeJS using `express`. Our application itself comes with the tool to run itself and accept the HTTP requests on some port that we bind to it. We do not rely on other dependencies to run the application for us.

## VIII. Concurrency
[Concurrency](https://12factor.net/concurrency). By following the other steps within the 12 Factor App, it means that we can scale our application horizontally by concurrency instead of vertically by adding more computing power to it.

What we're trying to achieve with steps such as *VI. Processes* is to easily scale or application by spawning more processes, and this is also why its the preferred way of scaling a 12 Factor App.

By keeping our processes stateless and by bundling our application into an executable, it means that we can spawn additional processes that will be up and running in just a few seconds, and start load balance the traffic to them.

The 12 Factor App also recommends us to use different type of processes for different type of jobs. For example we might use a web process to process HTTP requests, but we might use a Worker process to conduct some kind of processing.

## IX. Disposability
[Disposability](https://12factor.net/disposability). The way the other steps of the 12 Factor App lays out that we should be able to bundle and run our application quickly, or that we should be a be able to scale it by spawning more processes that by themselves are stateless, leads to our application also having to be disposable.

If we need to spawn and kill our application process on a moments notice when we scale up or scale down or application, we need to be able to handle that gracefully. 

What this means in practice is the following:

- We should be able to send a SIGTERM signal to our application and it should allow the current requests to finish before it shuts itself down.
- We should be able to spawn or kill our process quickly whenever we want.
- When we shut down a worker process, it should send the message back to the queue so that another process can pick it up.

By making sure that our application is disposable, it makes auto scaling the application much easier since we no longer need to worry about what happens when we dispose our processes.

## X. Dev/prod parity
[Dev/prod parity](https://12factor.net/dev-prod-parity). The tenth step of the 12 Factor App is regarding how we can keep our development and production environments as similar as possible.

Have you ever had that moment where someone in your team says "Well it works on my machine!" while the production site is faced with a blank screen and a HTTP 500 error? Its terribly annoying and it can also be very hard to debug code that work on one environment but fails on another.

The reason behind these situations can often be things like using PostgreSQL in production but SQLite in development, or perhaps you only defined the application dependencies but you have no way of defining the system dependencies.

Once again [Docker](https://www.docker.com/) is an amazing tool when it comes to this topic. It allows us to explicitly define not just our application dependencies, but also our system dependencies and backing services to make sure that what we run in production is exactly the same as we're running on our local machines.

By making sure that the Development and Production environments are identical, it gives the programmers confidence in the code they write and the tests they do. They can feel confident that whatever they have working on their Macbook, also will work fine on the AWS EC2 instance running in the cloud.

## XI. Logs
[Logs](https://12factor.net/logs). Reading a log on a single server is usually not a problem. You can just SSH into it and read it, voila. But what about when you have 10 servers or 1000 servers?  How do you then get a good overview of the logs you have?

The eleventh step of the 12 Factor App talks about the best practices of how you should collect your logs to make them a single stream of information that you can analyze and read to understand the state of your environment.

It makes a strong case that your application shouldn't be concerned about formatting log files and storing log on disk. Instead your application should just treat the log as a infinite stream of events that you output to `stdout` and that a third-party application reads in.

It makes things quite comfortable for you as the application developer, all you do is dump your logs to `stdout` and then you let another process worry about collecting, storing, formatting and analyzing it.

I enjoy using the Elastic Stack that is made up of Elasticsearch, Kibana and Logstash. The tools they offer allow you to collect logs in multiple different ways, including from files or from stream. Therefor in my mind I don't feel as concerned about if I store my logs as files or not. It will not make or break your collection process, however what the 12 Factor App is trying to make clear is that the responsibility of collection the logs, should not be a concern for your application.

One of the key reasons for this is that it loosely couples your application from your logs, and you can easily replace the way you collect the log information without having to do any changes to your code.

## XII. Admin processes
[Admin processes](https://12factor.net/admin-processes). The final step of the 12 Factor App talks about Admin processes or what we also call "Management" or "Maintenance".

Imagine for example that you want to automatically clear some table on a reoccurring schedule by using a cronjob. Or perhaps you want to have a command that an admin can trigger from time to time that clears the cache on the server.

All of these commands or tasks should be executed within your application to make sure that its being executed in the same context and environment. Imagine for example if your application use something like Django's Signals to listen on events and changes to your data. Maybe you want to automatically send an email or notification when an entry is deleted. 

Well if you clear the data by writing raw SQL queries to the database, you might lose some of this functionality. Instead the right way to do it is to create commands as part of your application, and execute them as such. 

Write a command called "clear_old_entries" and run it as part of your application with `python manage.py clear_old_entries` and execute it on your server, instead of writing some bash script that you execute from your local machine.
