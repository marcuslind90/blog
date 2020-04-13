---
layout: post
title: Review of Creating Process Flows using Django Viewflow
date: 2019-02-22 00:00:00 +0000
categories: docker
permalink: /@marcus/review-of-creating-process-flows-using-django-viewflow/
---

During the last few months, I've been working on a project for one of the largest retailers in the world where we use machine learning and data science to help them predict future sales.

This global company has a huge amount of data and one of the trickiest parts of the project is to gather all the data from their stores, users, and markets. Some data is accessible from API's while other data must be manually uploaded in Excel or CSV format by staff located all around the world.

My responsibility in this project was to build a dashboard and tool that would allow the staff to upload data, review results, start new runs and in general orchestrate this complex system. The tools I decided to use for this time-sensitive project was Django with [Django Viewflow](http://viewflow.io/).

## Use Viewflow to Map Out Complex User Flows
As you can guess from the introduction of this article, the flow that the user must go through quickly becomes complex due to it being dependant on many different factors. Different users might have different flows, or different parameters might affect which flow that the user has to take through the application.

This is where Viewflow comes into the picture. Viewflow allows us to generate a UI web flow and connect different tasks together based on the BPMN (Business Process Modelling) concept.

Imagine that you have a graph with different paths between views. You might start at View A and depending on what options you select on View A you might either go to View B or View C next. This is exactly what Viewflow helps us with.

By using Viewflows `Flow` class, we can map different handlers and views together by different conditions. It all ends up like a Form Wizard, but with more complex capabilities and without the need to necessarily finish the whole form in one go.

	::python
	from viewflow import flow
	from viewflow.flow.views import CreateProcessView
	from viewflow.base import this, Flow
	from .views import CustomView
	class FooFlow(Flow):
		process_class = FooProcess
		start = (
			flow.Start(
				CreateProcessView,
				fields=["field_a", ]
			)
			.Permission("can_foo", auto_create=True)
			.Next(this.second)
		)

		second = (
			flow.View(CustomView)
			.Permission("can_see_custom", auto_create=True)
			.Next(this.end)
		)

		end = flow.End()

As you can see in the code example above, we can use the `Flow` class to map `start` to next go to `second` and then go to `end`. Obviously, this is a very simple example, but you can also add conditions and other complexities that split up the flow in multiple paths.

## Views are Split Into Tasks
There are 2 main differences between Viewflow and a traditional step-by-step form wizard.

- Viewflow allows you to split up the flow into multiple paths depending on the input that the user provided. The flow is more dynamic.
- Viewflow split views into Tasks. You don't necessarily go from Step 1 - 10 in a single go, instead you can generate Tasks for the user to do in an email-style Inbox. This means that the user doesn't necessarily need to finish the work in a single sit-down, but instead different tasks in the process flow can be triggered at different times.

This second point was of huge value to us in this project. This allowed us to do 2 different key things:

- We could separate tasks to different users. User A might do Step 1-3, but then User B might do Step 3-6. We show the tasks in the correct user's inbox based on object-level permissions (using Django Guardian).
- We could trigger tasks using Python and Scheduled Tasks on certain calendar events. For example, we might want to generate a task and process to review the results of a Machine Learning job after the job has finished. 

I hope that you can already see the great value that Viewflow adds compared to traditional step-by-step forms. 

## Material Design in Viewflow
Out of the box, Viewflow comes with its own `django-material` library that gives us the ability to generate views that follows Google's Material Design framework.

This means that we can generate beautiful views without having to write any frontend code at all. All we have to do is to generate our views, create our forms and manage our business logic. Viewflow takes care of the rest.

This was also of a ton of value to us during our project. We were quite short on time and we had to produce a lot of work in just a few months, spending hours and hours of frontend work was not an option.

## Decouple Flow and UI Logic from Domain Models
How do you keep track on actions done by users that has nothing to do with the actual database model, but is purely a thing that you use to determine which view, status or flow to show to the user?

One way of doing it is simply to store it on the model like this:

	::python
	from django.db import models
	
	class Article(models.Model):
		has_been_reviewed = models.BooleanField(default=False)

The downside of this is that now we are putting view logic into our domain models. Pretty soon we will have a weird table that keep track on things that has nothing to do with the actual model. We want it to represent an `Article`, not represent the state of a Form.

Viewflow also helps us out with this, instead of forcing you to store things on your domain models, they separate the Flow or Task logic into what they call a `Process` model. 

A Process model might refer to your actual Domain/Business model, but it moves all of the state related to the form or the flow away from your business models. This means that you can keep your core business models clean and focused on what they actually represent, and it allows you to move UI/UX state to separate database tables where they belong. 

In the long term, this is an amazing thing. I've worked on other projects in the past where they've had a `Product` table that are 200+ columns. Do you really think that the Product has 200 different attributes? Of course not! It's just that they store a bunch of things that has nothing to do with the actual `Product` model within it. 

Decoupling this by this is gold worth, and especially when it comes "out of the box" and it's part of the whole framework pattern It encourages great code from the programmers working with it.
## Summary of Pros

All in all, the whole team are very satisfied with choosing Viewflow. It helped us to focus most of our resources on the actual Machine Learning model and Data Science, while at the same time be able to produce a high-quality dashboard and tool for users to interact with.

The main positives of using this library were the following:

- Minimal Frontend work required. Developers can focus on the actual business logic.
- Splitting up Views into Tasks. This allows us to be very creative with how we deliver the views to the users either by using Permissions or by scheduling the generation of the tasks.
- Object-Level permissions using Django Guardian comes working out of the box.
- Follow the traditional Django patterns of doing things. If you know how to use Django, it will be fairly easy to pickup the Viewflow framework.

## Summary of Cons

Even though we were happy with the decision to go with Viewflow, there were still some headaches and frustrations during the project that might stop me from using Viewflow again for certain types of projects.

- Lack of Documentation. The official documentation is terrible, it's mostly an API Reference and it lacks any substantial user-guides or deep-dives into features or topics.
- Too opinionated and Restricted. Viewflow has a lot of features out of the box which allows for fast iterations and development, but all of these features also restrict the possibilities that we have as developers. Simple things like changing UI elements or Data displayed in auto-generated tables or Forms might be incredibly tricky. 

Viewflow is a great choice if you're want to do the **exact** thing that Viewflow is built for, but if you want to go outside the box and tweak things the way you want them to be, you will run into a wall. 

I'm very happy with using Viewflow in the sense that it greatly speed up the development of our application, but as we go along with the project we will probably be required to replace it or at least built a secondary dashboard to allow us to build the custom features that we want. Keep this in mind if your project requires you to create a Custom UI or have micro-level requirements.
