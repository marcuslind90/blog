---
layout: post
title: Load Test Your Django Website Using LocustIO
date: 2019-07-01 00:00:00 +0000
categories: docker
permalink: /@marcus/load-test-your-django-website-using-locustio/
---

For the past year, I've been working on a project where I've been building a web product for one of the largest retailers in the world. The website itself is a private tool used internally by the company, but with over 100'000+ employees even an internal tool could receive a significant amount of user requests.

So how do you make sure that a web application is ready for a smooth release without performance issues when you finally open the flood gates to the users? The answer is to conduct what's called "Load Testing".

## What is Load Testing?
Unlike terms such as Unit Tests or Integration Tests, Load Testing does not necessarily test the details of the code and that certain actions return certain responses, instead it's a much higher level test where it mainly cares about response times and HTTP status codes.

For example, an integration test might test that when a form is submitted, the data is validated and a certain view is displayed with the result. With a Load Test, all we care about is that the form was able to be submitted and that the next view was successfully loaded.

We then repeat this process for tens, hundreds or thousands of simultaneous users and see if the behavior changes when the web application is under load. Does it still return an HTTP 200 status code? Do the response time spike to unreasonable levels? Are there any particular pages or actions that affect the performance in ways that stand out?

These are the type of questions we ask ourselves and that we look for answers to when we conduct load testing. By conducting this type of testing we can feel confident when we go into production that the website and the infrastructure will behave as expected and that we won't have an embarrassing release.

## Use LocustIO for Load Testing
[LocustIO](https://locust.io/) is a great, modern framework that allows us to simulate users visiting our web applications in a human-like way with random pauses between different page visits and actions.

It allows us to define what is called a `TaskSet` that contains multiple different tasks that a user request can do. These tasks can also be weighted so that some tasks occur more frequently than others which will simulate a realistic behavior by each simulated user.

For example, a task set to load test this website that you're reading this blog post on could look something like this:

    ::python
    from locust import HttpLocust, TaskSet, task

    class WebsiteTasks(TaskSet):
        @task(5)
        def index(self):
            self.client.get("/")
        
        @task(10)
        def blog_post(self):
            self.client.get("/@marcus/any-blog-post/")

    class WebsiteUser(HttpLocust):
        task_set = WebsiteTasks
        min_wait = 5000
        max_wait = 15000

So to clarify each part:

- We define a `TaskSet` that include 2 tasks, `index` and `blog_post`.
    - `index` has a weight of `5` and is a simple GET request to the index page of the blog.
    - `blog_post` has a weight of `10` and is a simple GET request to a specific blog post.
    - The weights mean that `blog_post` will happen 2x as often as `index`.
- We define a `WebsiteUser` that defines the simulated user's behavior.
    - The user should visit the tasks specified within the `TaskSet`.
    - The user should have a random wait time between 5000ms and 15000ms between each task. This is to simulate "realistic" user behavior and add some randomness to each request.

You can easily see how we could expand on this load test and add things such as:

- Login the user before each request to be able to visit private pages.
- Using POST requests to simulate submissions of forms and write to the database.
- Defining multiple different type of users that visit different type of tasks, perhaps we have an `Admin` user and a `Visitor` user for our blog.

Note though that since we are just defining different type of requests, we don't necessarily have the ability to mock data or use monkeypatching to prevent real data to be written to the database. Because of this it's recommended that this load testing is conducted on a staging server and not necessarily the production environment.

## Run the LocustIO Definition File
After we have defined the load test tasks that we want to conduct, it is finally time to run LocustIO with our file. For the sake of example, imagine that the code above was saved to a file called `locustfile.py`. 

To run the file, simply use the following command:

    ::bash
    locust -f locustfile.py --host=https://example.com

This will then run a web application that you can visit at http://127.0.0.1:8089 (If you run it locally) where you can run and review the load tests that gets executed to the `--host` parameter defined.

![](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/locust_welcome.png)

You will be greeted by this screen where you can define the number of users that you want to simulate, and the "hatch rate" or in other words "the frequency that they get added" to get to that maximum user count.

For example, if you set 200 users and 50 hatch rate, it means that LocustIO will do 0, 50, 100, 150 and 200 users as it scales up the requests to your web application.

## Review Result of LocustsIO Load Test
As you are running LocustIO you will see multiple different tabs available filled with data. At the time of writing these tabs will include "Statistics" and "Charts" followed by some additional sections.

All of this data is updated in real time as you run your load test, and you can therefore run the tests for extended periods of time and follow along. You do not need to predefine the length of the test and review it afterward.

In the Statistics tab you will see a table with an overview of each request and its success rate, failure rate, response time and content size. Here you will immediately see if any requests start to fail which in this context means not returning successfull HTTP responses due to high load.

![LocustIO Statistics](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/locust_statistics.png)

Within the Charts tab you can see the response time of the load test over time and you can easily see how the response time changes as new users are hatched and added to the total amount of simultenious requests that are simulated towards your web application.

![LocustIO Charts](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/locust_charts.png)

As we conduct our load testing, our main goal is to get the answers of:

- How many users can we accept without failed requests?
- How many users can we accept before response time become what we consider a "bad user experience"?
- Is there specific requests or tasks that fail much more often than others? Why is this?
- Is there bottlenecks in our application that spike the response time more than others?

An example of a bottleneck that I found when I was conducting the load tests of the web application that I was working on was that the authentication -- which relied on integration with a clients Active Directory server -- drastically increased the load time of the web site while other tasks could handle load fine.

LocustIO is a great tool that easily allows you to define load tests that you can commit to be part of your code repository which allows you to rerun them whenever you want. I highly recommend it for any project.
