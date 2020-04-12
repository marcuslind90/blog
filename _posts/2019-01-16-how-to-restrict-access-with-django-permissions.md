---
layout: post
title: How to restrict access with Django Permissions
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-restrict-access-with-django-permissions
---

Django has a very potent permission system that allow you to customize the access to different resources and views for each user depending on which group the user belong to, which permissions the user have, or by which specific objects the user should have access to.

This have come to use in many different projects that I've worked on and the use cases have ranged from restricting access to unauthenticated users, to having different types of users that should have different type of access, and to users only having access to articles that they are the author of, or items that belong to their specific company department.

Each of these use cases use both Django's Authentication system, but also its Permission system and in some cases extended functionality using the Django-Guardians package.

## Restrict access to unauthenticated users in Django Views
To simply restrict access to a view based on if the user is authenticated (logged in) or not does not require you to dive deep into the permission system at all, you can simply do it with Decorators, Mixins or the user `is_authenticated` property.

### Restrict access to logged in users in Function based views
If you're using function based views you can simply restrict all access to the view to users who are logged in, by decorating the function with the `@login_required` decorator.

	::python
    from django.contrib.auth.decorators import login_required
	
	
	@login_required
	def my_view(request):
		return HttpResponse()

The result of this will be that any user who is not logged in and who tries to access the view by its URL will be redirected to the login page of your website. Note that this decorator does not check if the user is active or not (using the `is_active` property), it only checks if the user is logged in or not. 

Normally you do not need to be concerned about this because the `AUTHENTICATION_BACKENDS` that come with Django will restrict any authentications from inactive user accounts, but if you have created your own backend this is something that its good to be aware of. 

### Restrict access to authenticated users in Class based views
If you're using Classed based views (Yes! You're doing it right ;)  ) you cannot just simply decorate your class with the `@login_required` decorator described above for the function based views, instead you have the following options:

#### Using the LoginRequiredMixin
In my humble opinion, this is the best way to do it and it is what feels most natural in the context of using Class Based Views. You simply include this Mixin to your class definition and voila its working, just as simple as using a decorator and it makes it clear to any other developer who comes along how it works.

	::python
	from django.contrib.auth.mixins import LoginRequiredMixin
	from django.views.generic import TemplateView
	
	
	class RestrictedView(LoginRequiredMixin, TemplateView):
		template_name = 'foo/restricted.html'
	
This results in the user either receiving a `PermissionError` or being redirected to the login page just like in the case of the `@login_required` decorator. The action that occurs depends on how the `raise_exception` parameter is set within your view.

You can also customize things such as the `login_url`, `permission_denied_message` or `redirect_field_name` by setting these values within the view. You can read more on the [Django documentation](https://docs.djangoproject.com/en/2.1/topics/auth/default/#the-loginrequired-mixin) of how you can customize the `AccessMixin` or the `LoginRequiredMixin`.

An example of a view using the mixin with customized parameters would be the following:

	::python
	from django.contrib.auth.mixins import LoginRequiredMixin
	from django.views.generic import TemplateView
	
	
	class RestrictedView(LoginRequiredMixin, TemplateView):
		template_name = 'foo/restricted.html'
		raise_exception = True  # Raise exception when no access instead of redirect
		permission_denied_message = "You are not allowed here."


#### Using the @method_decorator
The second alternative you have when using Class based views is to use the `@method_decorator`, this decorator is basically just a wrapper for other decorators and it allows you to use them on class based views. This can be particularly useful if there is a decorator you want to use, but you can't find a matching Mixin for it.

	::python
	from django.contrib.auth.decorators import login_required
	from django.utils.decorators import method_decorator
	from django.views.generic import TemplateView
	
	
	@method_decorator(login_required)
	class RestrictedView(TemplateView):
		template_name = "foo/restricted.html"

Since there already is a `LoginRequiredMixin` mixin available I suggest that you use it. In my opinion the use of inheritance when using classes is more clean and its more easy to understand what is going on.

Another thing to note that this approach does not allow you to pass in additional arguments such as the `login_url` that it should redirect to. These things will instead have to be configured within the project's `settings.py` file.

## Restrict access to views based on Permissions
The approaches above showed you how you can make a page public or private, how you can make a view that is accessible to the world and how to restrict access to only individuals with an user account. 

In some cases we might want to take it a step further and not only separate access by "public" or "private", but also by user. Imagine that we have "Employee" and "Administrator" users or "Sales Department" and "Marketing Department" users. Perhaps we want all logged in users to share what they see, except for a particular page that contain salary data and that we want to restrict to only administrator users.

This can all be achieved with Django's Permissions.

### Default Permissions in Django
When you have the `django.contrib.auth` app specified in your `INSTALLED_APPS` setting, it will make sure that 4 permissions are added to all the models of your application by default.

These permissions are:

- add: `user.has_perm('foo.add_bar')`
- change: `user.has_perm('foo.change_bar')`
- delete: `user.has_perm('foo.delete_bar')`
- view: `user.has_perm('foo.view_bar')`

You can also specify your own custom permissions to a model by setting them within the model's Meta class.

	::python
	from django.db import models
	
	
	class Foo(models.Model):
		
		class Meta:
			permissions = (
				('can_change_post_slug', 'Can change post slug'),
			)


### Add Permissions to Function Based Views
For function based views there is a decorator that is very similar to the `@login_required` decorator that we mentioned above that will allow you to not only restrict the view to logged in users, but also to restrict it to users with a specific permission, this decorator is the `@permission_required` decorator.

Use the `@permission_required` decorator to tag your view function with which permission that is required by simply specifying the permission as a string argument to the decorator.

	::python
	from django.contrib.auth.decorators import permission_required
	
	
	@permission_required("blog.view_post")
	def restricted_view(request):
		return HttpResponse()

The string argument representing the permission should be in the format of `"<app label>.<permission name>"`.

This results in the view being restricted to users who have the permission specified either by having it set to their user object directly, or by having a user that belong to a group that have the specific permission. If the user does not have the permission they will be redirected to the login page of your website.

### Add Permissions to Class Based Views
When it comes to class based views you can add restrictions by permission in very similar manner to when you restricted the view to logged in users above using the `LoginRequiredMixin`.

By using the `PermissionRequiredMixin` we can restrict access to our view and easily customize any behavior that we wish for in a pythonic way that is easy to understand for other developers who might pickup your code in the future.

	::python
	from django.contrib.auth.mixins import PermissionRequiredMixin
	from django.views.generic import TemplateView


	class PermissionRequiredView(PermissionRequiredMixin, TemplateView):
		template_name = "foo/permission_required.html"
		permission_required = ('posts.can_edit', 'posts.can_view', )
		
Note that instead of setting `permission_required` as a tuple of multiple values, you can also set it as a single string value. 

This will result in that your whole view will be restricted to users who have the permissions specified set to their user object directly, or whose user object belong to a group that have the specified permissions. If the user does not have the permission they will be redirected to the login page of your website, unless you specify the `raise_exception` attribute which will force the view to raise a `HTTP 403` error instead.

## Restrict access to specific objects with Django-Guardian
In the sections above we've learned how to restrict views by private/public access and by specific user permissions. But what if you not just want to restrict the access to a view in general, but you want to restrict the access to a specific object that is displayed on a view.

Let's take this website as an example. We have a dashboard that allow authors to login and create, update and delete their articles. Obviously we only want the author of the article to be allowed to update or delete it, if not then any author could login and edit anyones post -- you would be able to sign up and delete this specific post if you wanted. That wouldn't be good would it?

Within the [Django documentation](https://docs.djangoproject.com/en/2.1/topics/auth/default/#permissions-and-authorization) you might be able to find the paragraph that says

> Permissions can be set not only per type of object, but also per specific object instance.

At first when I read this I got all excited that this feature comes built in to Django, but hold your horses, it is not as amazing as it seems. These features only work if you're using the Django Admin. In the future they might add this functionality to the user object itself to make it simple to use anywhere on your website, but for now if we want to restrict access to specific object instances within our own custom views, we will have to find another solution.

The solution to this is [Django Guardian](https://github.com/django-guardian/django-guardian). With Django Guardian you can connect users to specific object instances and restrict access for anyone who is not connected or assigned to the specific object that they are trying to access.

Let's make an example, normally you might have a view that would look like this:

	::python
	from django.contrib.auth.mixins import PermissionRequiredMixin
	from django.views.generic import UpdateView
	
	
	class PostUpdateView(PermissionRequiredMixin, UpdateView):
		template_name = "blog/post.html"
		model = Post
		permission_required = "change_post"
		
Imagine that this is connected to an URL that is `/dashboard/posts/<pk>/`. This code would mean that any user who have the `change_post` permission will be able to see any view no matter which primary key (`pk`) that is provided in the URL. Ouch.

If you replace the `PermissionRequiredMixin` with Django Guardian's alternative (Notice the change in the import path) you would have the following code:

	::python
	from django.views.generic import UpdateView
	from guardian.mixins import PermissionRequiredMixin  # Changed
	
	
	class PostUpdateView(PermissionRequiredMixin, UpdateView):
		template_name = "blog/post.html"
		model = Post
		permission_required = "change_post"

This simple change makes it so that whenever a user access the view, Django Guardian will fetch the object by its primary key and check if the user have the `change_post` permission connected to the specific post. If not it will handle it just like a normal permission error and either redirect the user to the login page, or raise an HTTP 403 error.

### How to assign permissions in Django Guardian

So your final question might be, how do you assign the permission of the user to the specific object instance in the first place? Django Guardian makes this very simple with its shortcut helped function called `assign_perm`.

Personally I like to assign the permission with a Django Signal, which means that whenever the `Post` object is saved or updated, we will link it to its author and assign the permission to it.

	::python
	from django.db.models.signals import post_save
	from django.dispatch import receiver
	from guardian.shortcuts import assign_perm


	@receiver(post_save, sender=Post)
	def set_permission(sender, instance, **kwargs):
		"""Add object specific permission to the author"""
		assign_perm(
			"change_post",  # The permission we want to assign.
			instance.user,  # The user object.
			instance  # The object we want to assign the permission to.
		)
        