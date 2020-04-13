---
layout: post
title: How to Squash and Merge Django Migrations
date: 2019-01-30 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-squash-and-merge-django-migrations/
---

Django Migrations are one of the main features that keep me coming back to Django for most of the projects I work on. Being able to simply define the database model in python, and then sync it with the database schema using migrations adds so much value to a project.

Unlike frameworks such as PHP's [Laravel](https://laravel.com/) where you have to define your own migrations, Django will automatically create a migration file as soon as we change our model. It's like magic.

We all know that the initial version of our model rarely is the final, and we often iterate on our model definition over and over again as we develop new features for our application. This leads to more and more migration files being created and pretty soon you will end up with dozens of files that have to be applied when all you really care about is the final state.

Having dozens of files just laying around within your code repository that isn't actually in use creates confusion and make things appear messy. It's definitely not a best practice.

Wouldn't it be great if we can merge all of these migrations where changes cancel each other out and we just end up with a single file that contains the latest state of our database schema?

## How to use Squash Migrations Command
Django comes with a lot of different management commands that can be executed through the root `manage.py` file that brings a lot of valuable utilities to the table. 

The [squashmigrations](https://docs.djangoproject.com/en/2.1/ref/django-admin/#django-admin-squashmigrations) is one of these commands that can help us achieve just what we're looking for. It allows us to squash multiple migration files into a single one.

The way this works is that Django lists all of the actions from the existing migration files that you're trying to merge, and then attempt to optimize the list of actions by removing the ones who cancel each other out.

For example, if you first have a `CreateModel()` action and later a `DeleteModel()` action it knows that it can not only remove both of them, but also any modifying actions that have been done to the model in between.

The same is true for other actions such as `AlterField()` and `AddField()` that can just be moved into the `CreateModel` action in its final form. 

The final squashed migration file that comes out with the result of the command will also have references to all of the migrations that it replaced. This means that Django can then intelligently switch between referring to the old files, to instead refer to the new file when it needs to understand things as migration history or migration dependencies.

Django automatically enumerates the migration files that it generates by prepending a number. For example `0001_initial.py` is prefixed with `0001`. This allows it to keep track on which order that the files are created, and this number is also what the `squashmigrations` command use when we want to define which migrations to merge.

For example, imagine that we have a list of the following migration files.

	::bash
	./foo
		./migrations
			0001_initial.py
			0002_userprofile.py
			0003_article_user.py
			0004_auto_20190101_0123.py

In many cases, we might just want to attempt to merge all of them. We could do this by executing the following management command.

	::bash
	python manage.py squashmigrations foo 0004

`0004` refer to the prefixed number of the migration files and the result of the command is that it attempts to squash all the migrations from 0001 up until 0004. 

The command then generates a new file named `0001_squashed_0004_auto_<timestamp>.py`.

If you open this file you will see a few interesting things to note:

- The squashed file is marked as `initial=True`, meaning this is the new initial migration for your application. It does not depend on previous migrations from the same application.
- There will be a new `replaces=[]` attribute added to the `Migration` class with a list of strings that represent the file names of all the migrations that were squashed. This list will be used by Django to understand how the migration history and dependencies relate to your new migration file.

### Squashing and Migrating in Stages
Because of the `replaces` attribute in your new migration file, Django will not confuse the new migration with the old existing ones. This means that it's safe for your new migration to live in the same code base together with the old ones. There won't be any conflicts. 

This also means that we can deploy our new migration file and apply it to the databases of all our environments before we delete the previous files that it squashed.

This is exactly the way that [Django recommends us to do it](https://docs.djangoproject.com/en/2.1/topics/migrations/#migration-squashing). 

The order we do things are:

1. Squash existing migrations and commit to git.
2. Deploy and apply your new migration file to all environments.
3. Delete migrations and commit to git.

Hopefully, you just have to do this once. Unfortunately, the `squashmigrations` command is not perfect and there has been many times when I've used the command and it has resulted in various issues such as `CircularDependencyError`. 

## Solving CircularDependencyError
It is pretty common that when you use the `squashmigrations` command, it will result in a migration file that can't be applied because of various reasons. The reason is usually due to some kind of dependency that got broken during the merging of the files.

Whenever this kind of error occurs, the first thing I do is to delete my squashed migration and try again, but this time instead of squashing all of the migrations in my application, I do a subset.

I repeat this process until I find a subset of migrations that can be squashed and applied without error. This is an iterative process that I sometimes have to do over and over again while I work my way down to fewer and fewer remaining migrations. In the end, when I can't squash any more migrations, I will then attempt to solve my dependency error. At this point, we have hopefully simplified our migration files by squashing as many of them as possible so that it becomes more easy to identify the reason for the `CircularDependencyError`.

[The Django Documentation](https://docs.djangoproject.com/en/2.1/topics/migrations/#migration-squashing) gives the following information on solving `CircularDependencyError` that gets created due to squashed migrations.

> To manually resolve a CircularDependencyError, break out one of the ForeignKeys in the circular dependency loop into a separate migration, and move the dependency on the other app with it. If you’re unsure, see how makemigrations deals with the problem when asked to create brand new migrations from your models. In a future release of Django, squashmigrations will be updated to attempt to resolve these errors itself.

What this means is that your migration depends on another migration from another model to be run, while that model's migration also depends on yours. Because they depend on each other we call this a "Circular Dependency" because we can't figure out which one that is supposed to be executed first.

The solution to this is to break out the migration action that is causing the issue into its separate migration file, that you then apply separately. 

For example, instead of ending up with a single file, you now end up with 2 files.

- 0001_squashed_0004_auto.py
- 0002_manually_created.py

You then rearrange the dependencies from the files that are causing the `CircularDependencyError` so that they get executed in the correct order.

### How to Generate Empty Migration File
Normally when we want to generate a new migration we need to have some changes done to our model, if not you will face the *No changes detected in app* message. So in this case when we just want to generate a new file and move actions to it, and not necessarily do any actual changes to our model, then how do we achieve this?

We can simply use the `--empty` option to our `makemigrations` management command.

	::bash
	python manage.py makemigrations <app> --empty
	
By running that command we will now get a new migration file created in our `migrations` folder that automatically get some initial values, but with an empty list of operations to do. It will by default automatically add your latest migration (in our case it will be the squashed migration file) as a dependency.

All you have to do now is move the operations/fields/actions that are causing the `CircularDepedencyError` from your squashed migration file to the list of operations of your new empty migration file.

