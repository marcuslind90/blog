---
layout: post
title: 8 things you need to know to become a DevOps Engineer
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/8-things-you-need-to-know-to-become-a-devops-engineer/
---

As web applications get more complex with the need to scale to millions of users and the need to have to deliver new features multiple times per day, the demand for DevOps Engineers have been growing like crazy within the last few years. 

According to [StackOverflow 2018 Survey](https://insights.stackoverflow.com/survey/2018/#salary) DevOps Engineers are earning top dollar and engineering positions, being second only after the Engineering Manager position. Companies realize the value of good DevOps and there are huge opportunities for any engineer who want to take their career to the next level (together with their income).

I set a goal for myself during 2018 to get deeper into DevOps and now when I officially have my DevOps Specialization at [TopTal](https://www.toptal.com/#assume-solely-masterly-it-engineers) I hope that I will be able to do more DevOps-related projects throughout 2019. 

Do you plan to take the same journey and venture into DevOps? These are the things you will need to prepare for to take that leap.

## Basics of Linux
I'd be confident to claim that most of the work you'll be doing as a DevOps engineer will be on the Linux operating system. Even though Windows Servers are still used in many companies, the large majority of servers that you'll be working on in any Technology Company or Start Up will be running Linux.

Even though I've been forced to be in contact with the Linux Terminal since the very beginning of my career, its still alway felt a bit intimidating to me. For years I was able to get away with just knowing the absolute basics of it, so that I could navigate around, debug things, read logs and restart services. 

When I started my journey into DevOps this had to change. Don't worry you are still not required to know every single bit about Linux and be some kind of guru, but you definitely need to know enough to be comfortable with the following things:

- How to run, restart and terminate services/daemons/background processes.
- How to set and work with Environment Variables.
- How to install packages and download files.
- How to setup Crontab/Cron jobs.
- How to write simple bash scripts with loops and if statements.
- Permissions and groups with `chmod` and `chown`.

I feel that with a solid understanding of those tasks and concept, you will be in an okay position to move forward with your DevOps ambitions. Note however that this does not mean that it isn't valuable to expand your knowledge of Linux additionally. Since Linux is part of so much related to the field of DevOps any additional time you invest in it will give you a great return for the future.

## Basics of Networking
Unless you are only working with tools such as Heroku or AWS Elastic Beanstalk that automate some of the work for you, one of the first thing you have to do when you create a new application infrastructure in the cloud, is to setup a virtual network (VPC).

As a DevOps engineer you are expected to have a great understanding of the infrastructure of the application you're working with, and that also includes the network side of things that can be crucial for securing your application from malicious attacks.

Which instances require internet access? Which instances need to be able to communicate with others? What ports should the instances be allowed to communicate on? All of these are questions that require answers from you in the role of a DevOps engineer and to answer them properly you need to have a good understanding of the basic concepts of networking.

- How to work with Firewalls and Ports?
- What is a CIDR IP Block?
- How does a load balancer work?
- Should I refer to the instance using the public or private IP?

Some cloud providers such as Amazon Web Services or Microsoft Azure allow you to be very detailed with your networking configuration by creating Subnets, defining Route Tables, Creating CIDR Blocks of which IP-addresses should be used etc. Other providers such as DigitalOcean chooses to simplify things and limit the options that you can configure for your private network. However, no matter which Cloud Provider you'll be working with, you still need to have a good understanding of how the underlying network works and how the nodes are communicating with each other.

There's a huge difference if you let the application connection to the database on the public IP that goes across the internet, or the private network address that use the internal network. You need to understand why this is so that you can make the best decisions for the application you're working on.

## Automatic Configuration of Instances
In the beginning of my career I was working at a web agency that was hosting all of the clients website on a single web server that we FTP'd into to update files on. The server itself was gold worth to us and nothing was allowed to happen to it. That's not really how things work anymore.

These days, servers are not like pets that we love dearly, they are cattle that can be replaced in an instant. Depending on your setup, you might create a new server instance every time you deploy code. This means that you can not rely on having to manually go into a server to set Environment Variables, Install Dependencies, Securing the server etc. All of this must happen automatically whenever the instance is provisioned.

In other cases, it might be that you have a cluster of hundreds of servers that you might need to modify in some way. SSH'ing into each one would not be a very nice option.

So how do we achieve this? Well there are plenty of tools out there that you could use that will fulfill your needs.

- [Ansible](https://www.ansible.com/)
- [Chef](https://www.chef.io/chef/)
- [Puppet](https://puppet.com/)
- [Fabric](https://www.fabfile.org/)

Each one is a deep topic by itself. Personally I enjoy using Ansible, but as long as you have an understanding of at least one of these type of tools you will go a long way and it will cover your needs.

On top of this, it would also be great to have a very solid understanding of writing Bash scripts. In many cases when all you want to do is some very light weight configuration when a new server is created, a simple bash script might be the best solution for you.

## Docker and Containerization
Docker was my first step into DevOps. As a background as a traditional backend software engineer I was always struggling with dependencies and emulating the production environment on my own local machine as closely as possible. I've had my fair share of "but it works on my machine!" moments -- believe me.

Since I got a hand of Docker I've incorporated it into every single project I've worked on for the last 2 years. I'm amazed by it and stunned when I run into people who've used it but didn't like it for their own personal work flow or projects. In my mind no matter if you're aspiring to become a DevOps engineer, Docker is still a must-know for any developer. You just can't miss the amazing benefits it has to your work. 

Related to DevOps though, Docker and Containerization fills a very important role. It allows us to package our application into a single image that can be executed/started/run within a few seconds which is incredibly important when you do things such as auto scaling where you shut down and create new instances all the time and whenever you do, you want each instance to be able to accept traffic to it as soon as possible.

On top of that, it also makes the developers confident that the code they are writing will work as well in a production environment as it does on their own local machines. There is no difference in database version, which web server is being used etc. It's mirrored exactly point by point and if it works for the developer on the local machine it should ( :D ) work when its being executed on the server.

Some tools comes and goes. I feel confident that Docker is here to stay for a while, and investing the time to learn it properly will be a great investment of your time.

## Terraform and Infrastructure as Code
Getting familiar with a code provider is a lot of work. Amazon Web Services offers multiple types of certifications of how you provision infrastructure using their platform and their dashboard and services are vastly different from other providers such as Microsoft Azure, Google Cloud or DigitalOcean with its own proprietary tools and configuration syntax.

I've spend a lot of time with AWS and I have had my moments where I've sighed at the thought of having to work with a project on a completely other platform where I have to learn how to do certain things all over again. Wouldn't it be amazing if there was a way to standardize/normalize the way we setup infrastructure so that you can follow the same practices no matter which provider you work with?

[Terraform](https://www.terraform.io/) is an amazing tool that allow you to do this. It has its own JSON-ish configuration syntax that allow you to define your complete infrastructure as code, using any of the supported providers that is integrated with the tool. AWS has a similar thing called [CloudFormation](https://aws.amazon.com/cloudformation/) that fill the same role, but out of the two I would go with Terraform any day since it will work no matter which Cloud Provider you work with.

When I was first introducer to IaC (Infrastructure as Code) I have to admit that I did feel that it was a bit "overkill" for web projects that did not require a complex infrastructure. I felt that if all you needed was a web server and a database. Why not just set it up on a dashboard? As soon as I started using Terraform and opened my eyes for how it can be used, I quickly changed my mind.

Now I use Terraform and IaC for all my projects, no matter if I determine the infrastructure to be complex or not. I found that when I define my infrastructure as code, I have a much better understanding of what I have running at any point in time and how each object in my infrastructure is configured -- and I won't forget it.

I've had projects that has been running for a while and when I got back to them I forgot that I also had a Memcache instance running for it, or I forgot to shut down that old SQS Message Queue that I wasn't using any more. These issues will all be gone as soon as you switch to defining your infrastructure as code part of your application repository.

On top of that, it will also greatly simplify any migration of your application to a new cloud provider. Imagine if you start off with using DigitalOcean due to its simplicity and cheap pricing, but as you keep building your application and it gets more complex, you realize that perhaps AWS would be a better choice. If you have all your infrastructure documented and written down as code, the migration will be a breeze.

## Continuous Integration and Delivery Pipeline
The answer to "What is DevOps?" seem to differ for each person that you ask the question to, however if we go for the Wikipedia definition it would be *"The goal of DevOps is to shorten the systems development life cycle while delivering features, fixes, and updates frequently in close alignment with business objectives"*.

The key point here is "shorten the systems development life cycle" which could be translated to "shorten the time it takes for new code to go into production". 

The way we achieve this is by automating the deployment process. When new code gets commited to the release branch of our repository, we want to automatically deploy it to production as fast as possible, and as reliable as possible. This type of deployment process is called a Continuous Integration & Continuous Delivery Pipeline, or CI/CD Pipeline.

Since this is one of the key roles of DevOps, you definitely need to have a solid understanding of how this kind of workflow works and how you achieve it. You need to understand the difference between Continuous Integration and Continuous Delivery, and you have to know the best practices of that type of pipeline. 

There's plenty of free tools you can use to get going with this. You can install Jenkins as a Docker Container on your local machine or you could just use any of the following tools that offer free trials or free pipelines for public repositories:

- [Travis CI](https://travis-ci.com/)
- [Circle CI](https://circleci.com/)
- [AWS CodePipeline](https://aws.amazon.com/codepipeline/)

## Logging and Monitoring with Elastic Stack
In the previous headline we determined that one of the fundamental points of DevOps is to increase the speed of release cycles and how fast we can release new features to our users. This does not only mean that we should find ways to deploy things automatically (using CI/CD Pipelines) but it also means that we want to find ways to better understand our application so that we know how to improve it.

Being able to monitor our infrastructure, keep track on events and understand what issues our application is having, allow us to understand our application better which means that we can improve the quality of our work and the speed of how fast we improve our application and add value to our company.

The first step of logging is to just log it to a file on your server. Its a great start but as soon as you scale your application to use more than 1 server, you will quickly realize that it might not be enough to easily keep track on what's going on. You will have to go into different servers to read different type of logs and it would be much better if you could collection the information of all your instances on a single location. 

This is where the ELK or the Elastic Stack comes into the picture. ELK is an acronym of the tools used within the stack and its made up of:

- [Elastic Search](https://www.elastic.co/products/elasticsearch) is used as a database or storage for all your monitoring data and log entries. 
- [Kibana](https://www.elastic.co/products/kibana) is used as a dashboard and interface for where you can have a great overview of what is going on with your application.
- [Logstash](https://www.elastic.co/products/logstash) allows you to easily collect logs and data from your instances.

All of these tools are offered by the company Elastic and that's why its often referred to as "The Elastic Stack". 

By setting up a monitoring instance using these tools you will be able to collect the data from each instance within your infrastructure and have an overview from within a single dashboard. It's great!

It might be a bit too much when you have a simple application. But if you're expected to do DevOps work for clients of any size, this is definitely something that is good to have experience of and it will be a core part of how to properly understand the status of your application.

## Database Scaling and Backups
Databases are one of the core parts of any type of web application. Not only is it almost always used, but its also one of the most vulnerable parts and one that fail the earliest when we start scaling and receiving a significant amount of traffic. You will experience database problems at some point in your applications life time, I guarantee it.

Some cloud providers such as Amazon Web Services or Microsoft Azure offers managed databases, others such as DigitalOcean require you to provision, scale and monitor your own database. No matter if you outsource the management of it or you do it yourself, both cases require you to have a solid understanding of what is going on so that you can identify and isolate any problems that might arise.

You should have a good understanding of the following topics for your database of choice:

- How do you setup automatic backups?
- How do you replicate and horizontally scale your database?
- How do you monitor and debug performance issues?
- How do you ensure "High availability" and automatic fallbacks?

If you can setup a demo project where you illustrate that you know the answers to all of these questions, you will be in a great position for when you move forward with your DevOps career and the type of problems that you might encounter related to databases.
