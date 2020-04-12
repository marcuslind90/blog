---
layout: post
title: Deep Dive into Building a REST API The Correct Way
date: 2019-02-09 00:00:00 +0000
categories: docker
permalink: /@marcus/deep-dive-into-building-a-rest-api
---

RESTful API's are one of the main design patterns that you choose between when you're setting up a new API for your application. The term gets thrown around a lot, and unfortunately many API's ends up becoming some kind of mix of multiple patterns that are half-way implemented due to lack of understanding on what REST actually is.

This creates an API that feels unnatural for developers to use which might slow down development and confuse programmers. Usually, the reason why we create API's is that we want to allow other members of our team, or the public, to access our code and features. Because of this, the design of the API is important and it should be of high priority to keep things neat, clean and logical.

The RESTful style of creating API's are not necessarily the "best" one. There are different patterns and each one might be good depending on the job that you want to do. But REST API's are extremely common and I'd dare to say that most public API's follow the RESTful pattern.

Because of this, as a software engineer, it is very important that you have a good understanding of what REST means.

## What is a RESTful API?
REST stands for Representational State Transfer and as you might be able to infer by its name, it is a style of creating API's that allows you to communicate the state of the stateful server to the client in a representational way.

Well, what does representational mean in this context? It means that we give the client a window into each resource that we store on the server where the client can properly understand the resource in the same structure as it is being stored. 

Now, "structure" does not necessarily mean "format". You might store your data in a MySQL database, but the format that your API exposes the data in might be HTML, XML or JSON. What we mean by "structure" is that we give the user the ability to see the fields or data points of our state without modifying, merging or transforming it.

For example, if we have an "Article", an "Category" and an "User" data resource that is stored in our database, then our API will expose these resources individually just as they are stored in the database. We will not construct some kind of weird, mixed response that merge these things together. That would not be "representational" of our data.

### What are the Constraints of REST API's?
To be able to call your API a pure REST API you need to make sure that the design of your API follows the following constraints.

- **Client-server Architecture**. This means that we separate the user interface concern to our client, and the data storage concern to our server.
- **Statelessness**. Our API should always be stateless and it does not matter which client that access a resource, the resource should always be represented in the same exact manner. If we need to keep track on session state, then that is the concern of our client, not our server or API.
- **Cacheability**. One of the main backgrounds to why the RESTful style was developed, was to improve the performance and scalability of the web. It is important that the API explicitly, or implicitly, define itself as cachable or not, to make sure that the client can skip or ignore as many requests as possible.
- **Layered System**. Just like the requirement for cacheability, it is important that the client cannot tell if it's being connected directly to the end server or through some kind of proxy. This allows us to keep our API behind a load balancer and improve scalability and performance.
- **Uniform Interface**. This is one of the most crucial things to REST API's and it is what most people think of when we think of REST. It is made up by the following 4 points.
	- **Resource Identification in Requests**. Each resource is clearly identified in each request, for example we might have a `/api/users/` request that is explicit for the users resource, or a `/api/articles/53/` request that is explicit for a specific article resource.
	- **Resource Manipulation through Representation**. The information that the client receives or holds for each resource, should be enough to also allow for manipulation of said resource.
	- **Self-Descriptive Messages**. The responses themselves should contain enough information to inform the client how to process them. This includes setting the media type to e.g. `application/json`.
	- **Hypermedia/Links To Identify Actions**. We use links to inform the client how to navigate to new resources or how to conduct specific actions. For example, if we have an Article resource that refer to a Category, we should refer to that Category using a Hyperlink so that the client easily can navigate to the Category resource and fetch additional information. The client should not require hardcoding these additional actions or references.

All of these constraints should be fulfilled to be able to call it a "RESTful API". In reality though, a lot of API's out there skip some of these constraints but still refer to themselves as RESTful. For example, instead of referring to resources using Hyperlinks they might do it using Primary Keys and IDs.

### REST API in Practice as a Web Service
All of these constraints that I listed above might feel a bit vague or "formal". What does all of this translate to in practice? How do we design a REST API using this information?

The RESTful style of creating an API does not necessarily restrict you to designing it for the web and the HTTP protocol. But for the sake of giving a practical example, I will expect us to set up a web API.

REST does allow us to do CRUD actions to each of our resources. This means that we can Create, Read, Update and Delete each resource. Since we are using the HTTP protocol, we will do these actions using different HTTP verbs such as 

- GET, used to read a resource. 
- POST, used to create a new resource. 
- PATCH, used to update an existing resource.
- PUT, used to replace an existing resource.
- DELETE, used to delete an existing resource.

Since we want to follow the first constraint of sticking to a client-server infrastructure, we want to make sure that the server is not concerned at all with things such as user interface or how the data itself is used and displayed to the user. That is the client's concern. Because of this we will represent all of the data in our API using JSON.

#### Structure the REST API URI's

Let's imagine that we have the following 2 resources:

- Article
- Category

Remember how the "Uniform Interface" constraints require us to identify each resource through our requests? Because of this we will set up separate endpoints for each resource:

- `/api/articles/`, List a collection of Articles.
- `/api/articles/<id>/`, Display a single Article.
- `/api/categories/`, List a collection of Categories.
- `/api/categories/<id>/`, Display a single Category.

By structuring our API in this manner, it is very easy for the client to know which resources it is fetching, and it is very easy to update or modify a single, specific resource. 

On top of that, we can also make sure that each response is stateless. We do not have a `/api/get_current_article/` or `/api/get_liked_categories/` that depend on the logged in user or the state of the client, instead the client is explicit about fetching the exact article it wants. This also makes things very Cacheable, another constraint and requirement for our RESTful Design.

#### How to Structure the REST JSON Response
As stated earlier, the response of our API should represent the resource on the server. This does not necessarily mean that we have to display all of the information, for example in the database we might store the user's password, but we might not include it in the response.

This means that we might exclude some data from our response, but we will still represent the resource fairly and properly. We want to give a good representation of our data to the client.

Let's then say that we have the following fields in our Article Table in our database:

- Title
- Content
- Categories

We might then represent this as the following JSON:

	::json
	{
		"title": "5 Steps To Build a Great API",
		"content": "Here we have a lot of content that can be quite long.",
		"categories": [
			"https://api.example.com/api/categories/1/",
			"https://api.example.com/api/categories/2/",
		]
	}

Note that we first of all give a good representational response of our data. We do not merge it all into a single HTML response, rename the fields or in any other way modify the response. 

Second of all, you can see that we use Hyperlinks to refer to the Categories that the Article is tagged in. This means that our client can incredibly easily move into each Category and fetch additional information and data of each without necessarily having to know how to construct those requests from within the client beforehand.

## Common Mistakes in REST API Design
I have worked in a ton of different projects that make use of RESTful API's to display its data to some client or to some other service. Most of the times it work out fine, but I have seen plenty of mistakes being made that I think we can all learn from.

### Mixing REST with RPC
One of the most common mistakes is to simply not create a pure REST API, and instead create some kind of mix of REST and RPC because its "easier" at the time. This makes the whole experience of interacting with the API confusing, and it slows down development when new team members are added to the team.

Stick to a single one and try to create an as pure experience as possible.

An example of this would be if we have a contact form that sends away an email somewhere. A fairly common approach, which would be a mistake,  would be to create an endpoint that look something like `/api/send_email/`.

Does this represent a resource? NO! It's an action. This is confusing in the context of RESTful design.

The proper way to do it would be to create a URI that look something like `/api/messages/` and do a HTTP POST request to it to CREATE a resource (Remember the CRUD actions?). Then our server might use a signal or create some kind of side-effect that then in turn sends the message to the email.

So our REST Action simply create the resource, not just execute an action.

### Attempting to Reduce Requests By Increase Response Body
I once worked on a project where one of the lead engineers must have had some deep fear of HTTP Requests and he did everything in his power to reduce the amount of requests, by attempting to merge in as much data in each response as possible.

For example, instead of having a request to fetch the Article that the viewer wanted to see, it also pre-fetched all the "recommended articles" on the page and all the data that the user **might** want to see.

This resulted in huge responses that took seconds to load, and due to merging multiple types of resources that didn't have direct relations to each other, it was also difficult to make efficient SQL Joins. 

He was successful in reducing the amount of API Requests, but he was not successful in creating a high performance, smooth experience.

REST API's are designed to be friendly to caching and performance. Don't be scared of requests, don't attempt to over-optimize each response by modifying, merging and changing the data structures. Keep things simple.
