---
layout: post
title: How to Change Name of Django Application
date: 2019-01-31 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-change-name-of-django-application
---

Updating the name of an existing Django App is easier said than done. After you've renamed your folder name you will instantly be met with errors and different issues that result from dependencies to the old app name.

Many times the first version of your application is not the final one, and your code base might go through thousands of iterations where you slowly add, remove or change the features of your app.

Sometimes these changes are major refactors which includes migrating code or models from one app to another or renaming existing apps to make more sense in the context of the updated code base.

So how do you avoid these errors? What is it that you are required to do to migrate an application from folder A to folder B or to simply change its name?

## Step-by-Step List to Changing App Name
The name of your Django applications are referred to all over the place and there is a list of actions that you have to take to complete the changes.

1. Rename the folder of the application you want to update.
2. Update any dependencies and import statements to the folder you updated.
3. Update database entries for the `django_content_type` table to refer to the new application's `app_label`.
4. Update the table names of any models that you haven't explicitly set the table name of. These table names are inferred by the application name and need to be updated.
5. Update database entries for the `django_migrations` table and update the application reference for each migration by setting the `app` field to your new app label.
6. Update any namespaced folder names that are within your `/static` or `/templates` folder. For example, you might have `./foo_app/templates/foo_app/index.html` and it should be updated to `./bar_app/templates/bar_app/index.html`.

On top of this, if you have also updated your model names or if you've updated the folder that contains a virtualenv, you also have to take the additional steps of:

- Rename your Django models within the `django_content_type` table. This is done by updating the `name` column to the new model name.
- Delete and recreate your virtualenv folder and reinstall all dependencies.

Let's walk through all of these tasks in more detail to take you through how you do each one.

### 1. Rename Django App Folder
Renaming the application folder is a very straight forward thing to do. Just... rename it. However, if you use the correct tools it can also simplify and minimize the manual work you have to do to update all the references from the old folder name to the new one.

For example, by using [PyCharm](https://www.jetbrains.com/pycharm/) you can right click on your folder name and select Refactor->Rename and you will get a popup with some additional options.

Here you can then decide if you want PyCharm to automatically attempt to update any file paths, import paths or other references to the directory automatically. 

In a large code base, this might save you a ton of time! Be careful though, if you have applications named common things such as "core", "app", "config" etc, PyCharm might make mistakes and update the wrong references.

For example, imagine that you have a Django app named `core` and you want to rename it to `myapp`. Let's then say that you have the following code somewhere in your code base.

	::python
	from django.core.files.storages import default_storage
	from core.models import MyCustomModel
	...

PyCharm **might** then rewrite both of these import statements to

	::python
	from django.myapp.files.storags import default_storage
	from myapp.models import MyCustomModel

This rarely happens, but it is something worth to look out for.


### 2. Update any Dependencies or References
This step is significantly made much easier by following the advice in the previous section to use a tool such as PyCharm.

By using the PyCharm Refactor->Rename action, you can make it automatically update any uses of the application name within your code base and fix any import statements or dependencies.

If you don't have the access to something like PyCharm, I would attempt to perhaps to it with a Regular Expression, or in the worst case search the whole code base for any usages of the old folder name and update it manually.

Here below you can find a few examples of regular expressions that could be used to find any references to an old application named `foo`.

- `^(from|import)\s(foo)` will match any import statement that your old application name is used in.
- `["'](foo)['"]` will match any string value that is the name of your old application.

You can use these regular expressions to then automatically replace any references to your old name with your new name, without having to manually go through each file by yourself. 

If you use VSCode or other smart IDE's that can do Regular Expression Group Match Replacements you could then refer to other pieces of the regular expression and only replace parts of it. 

Finally, if your code base is relatively small, or if your application is named with more unique names that might not occur all over the code base in other contexts, you could simply just search for any instance of your old application name and update them manually.

A few good locations to look for when we are talking about references or dependencies would be:

- Import statements
- Models Meta app_name value.
- `INSTALLED_APPS` settings 
- Docstrings and other Documentation or texts that refer to applications.

6. If you set `app_name` in Models Meta classes or the `name` in your application's `AppConfig`, you need to update these to point to the new label.

### 3. Update Django Content Type Table
By default, you will find the `django.contrib.contenttypes`  application within the list of `INSTALLED_APPS` in your `settings.py` file. This is a core application within Django and its used to keep track of the different models and content that is available within your app.

Anytime you add applications and run migrations, this table adds references to the models to the `django_content_type` table within your database. Whenever we rename an application or a model, it then also means that we have to update the references from the old application to the new application within this table.

The main query you need to run is the following:

	::sql
	UPDATE django_content_type SET app_label='<NewAppName>' WHERE app_label='<OldAppName>';

Obviously, you should replace the `<NewAppName>` and the `<OldAppName>` with your own names to be able to run the query successfully. What this query does is that it simply updates all the lines within the table that contain your old app name as the `app_label`, to the new app name.

If you have updated any model names within your application, you will also be forced to run a second query to update the `name` field of each row within the `django_content_type` table.

	::sql
	UPDATE django_content_type SET name='<newModelName>' where name='<oldModelName>' AND app_label='<OldAppName>'

Once again, you should obviously replace the `<newModelName>`, `<oldModelName>` and `<OldAppName>` with your own versions for the query to be executed.

### 4. Update Model Table Names
If you have any Models in your application (which you probably do) it is fairly common that programmers let Django infer the name of the model table by the name of the application combined with the name of the model.

For example, if our `foo` application has a `bar` model within it, the automatic table name would become `foo_bar`. You can also set this to some explicit value by updating the `Meta` class of your model in the following manner:

	::python
	from django.db import models

	
	class Bar(models.Model):
		...

		class Meta:
			db_table = "custom_bar"

So when it comes to making your models work properly after you've updated the app name, you have 2 options:

- Set the `db_table` value for all of your models to refer to the old application name and the existing table name.
- Update all the existing table names to match the new application name.

Personally, I prefer the second option, because it makes sense that things are named "properly" instead of having some tables refer to some old application name that doesn't exist anymore. That could be confusing when new developers join our project and take a look at our database.

The query used to update table names are the following:

	::sql
	ALTER TABLE old_app_model_name RENAME TO new_app_model_name;

You will need to run one of these queries for each of the model tables that you have. To get a list of all your table names you can connect to your database and run `\dt` on PostgreSQL or `desc tables;` on MySQL to get a full list of tables in your database.

### 5. Update Django Migrations Table to New App Name
Django allows developers to automatically generate migration files that represent changes to the models in Python, that then gets migrated to the selected database and applied as SQL queries.

Each time a migration is applied, Django will need to store the state of the migration so that it never attempts to execute the same migration twice. This is done by storing references to each migration in the `django_migrations` table. 

The migration table in the database contains references to which application that the migration relates to, this is stored in the `app` column. Since we changed our application name, it also means that we will need to update all the references within the `django_migrations` table to prevent Django from attempting to re-applying all of our migrations.

This can be achieved with the following query:

	::sql
	UPDATE django_migrations SET app='<NewAppName>' WHERE app='<OldAppName>'

### 6. Rename Namespaced Folder Names in Static or Template Folders
A common practice in Django is to namespace any static or template file that you have in your application with the name of the application itself. This is done by putting all the files within a directory named by the application.

For example:

- No Namespace: `./foo/static/js/index.js`.
- Namespace: `./foo/static/foo/js/index.js`. 

What this leads to is that when Django later collect all the static files and dump them in a single folder, it will separate them out by the application. This helps to prevent overrides or naming collisions.

Because of this common practice, we have to make sure that any `static/` or `/template` folders that exist in our app get updated with the new application name as the namespace.

Because of this, it also means that we should update any references to these files. So anywhere where we load static files or templates from within our templates or python files, we should also properly update it to use the new namespace.

## Conclusion
That's it! You should now be able to run your application again after you have renamed one or more of your Django apps. At times this whole process might feel very frustrating and cumbersome, but we should also remember that all of these things are there to add value to Django.

For example, it might be tiresome to have to update the `django_migrations` table with the new app name, but at the same time, the fact that we have a table like that makes our job as programmers so much easier when it comes to migrating database schema changes.
