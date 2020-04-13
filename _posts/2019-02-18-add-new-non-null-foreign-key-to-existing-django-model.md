---
layout: post
title: Add New Non-Null Foreign Key to Existing Django Model
date: 2019-02-18 00:00:00 +0000
categories: docker
permalink: /@marcus/add-new-non-null-foreign-key-to-existing-django-model/
---

Did you ever attempt to add a new non-nullable ForeignKey field to an existing Django model? If you did, you were probably prompted to add a default value that existing data should use for the new Foreign Key. But what value should this be? How do you automatically set it to the right value?

![foreign key default value prompt in terminal](https://coderbook.sfo2.digitaloceanspaces.com/files/articles/inlines/foreignkey_default_value.png)

I was recently working on a project where the requirements had greatly changed throughout the iteration of the project. We had gone from a quite simple model that got more and more fields added to it, and it ended up with multiple many copies of the same model instances with only slight changes to the data. 

It made a lot of sense to refactor this database model and to split it up into a parent and child model, which meant that any items that shared most of the data could inherit from the parent, and only specify the new data in the child.

E.g. instead of doing something like this:

	::python
	from django.db import models

	class FooModel(models.Model):
		field_a = models.IntegerField()
		field_b = models.IntegerField()
		field_c = models.IntegerField()
		field_d = models.IntegerField()
		field_that_is_updated = models.IntegerField()

We could simply refactor it into something like this:

	::python
	from django.db import models

	class BarModel(models.Model):
		field_a = models.IntegerField()
		field_b = models.IntegerField()
		field_c = models.IntegerField()
		field_d = models.IntegerField()

	class FooModel(models.Model):
		parent = models.ForeignKey(BarModel, on_delete=models.CASCADE)
		field_that_is_updated = models.IntegerField()

Note that the new `parent` field is not nullable. So what would happen to all the existing `FooModel` entries? Which `BarModel` would they point to?

This is a very common scenario that you will definitely run into. Sometimes I see the lazy solution which is to simply make it `null=True`, this makes the migration pass but you will still run into the issue that the old entries no longer are complete. 

How did I solve this problem where we want to add a new `ForeignKey` field to a model that is not nullable, and we don't have any existing data to point these existing entries to?

## Migrate in Multiple Steps

We can achieve this by creating multiple migration files that execute the changes to our models in incremental ways. We will step by step do the following things:

- Create a new Model and add new `ForeignKey` that is nullable.
- Write custom migration that generates the data for old entries.
- Remove migrated fields from the original Model.
- Remove nullable from the new `ForeignKey` field.

All the migrations get executed synchronously one by one, and we end up with a non-nullable `ForeignKey` that is populated with data that has been created and generated during the migration process.

Sounds good? Let's do it!

### Instantiate New Models and Allow Null Foreign Key

The first step is to set up our new Model, create a `ForeignKey` field to it, but keep the fields that you want to migrate in the old model and make sure that the `ForeignKey` is nullable.

This allows us to set up the new model while still keeping our original data in the existing model's table. We don't want to delete the fields and the data with it just yet.

At this point in time, our code would look something like this.

	::python
	class BarModel(models.Model):
		field_a = models.IntegerField()
		field_b = models.IntegerField()
		field_c = models.IntegerField()
		field_d = models.IntegerField()


	class FooModel(models.Model):
		field_a = models.IntegerField()
		field_b = models.IntegerField()
		field_c = models.IntegerField()
		field_d = models.IntegerField()
		field_that_is_updated = models.IntegerField()
		parent = models.ForeignKey(BarModel, on_delete=models.CASCADE, null=True)

Note that we added our new `BarModel` and we added a `ForeignKey` to it from the `FooModel` that got `null=True`. Also, note that the `field_x` fields are duplicated in both models at this point in time.

### Write Custom Migration that Generates Data

Next, we want to fill the new `BarModel` table with data and point the existing `FooModel` entries to these new table rows with its `ForeignKey`. We can achieve this by creating a custom migration file that we will with our own content.

	::bash
	python manage.py makemigrations --empty myapp

The command above will generate a new migration file to the `myapp` Django application. This newly generated file will contain an empty `operations` list that you can fill with your own actions that you wish your migration file to execute.

The `migrations` package is filled with many useful actions that you can execute during migration such as (but not limited to):

- Add new fields.
- Delete new fields.
- Run custom SQL.
- Execute Python script.

The last point is what is interesting to us, we can make our custom migration execute python code as the migration gets applied. Awesome! 

We can leverage this feature to then generate the new data on the fly and populate the `BarModel` with data from the existing `FooModel` entries, and then point the `FooModel.parent` field to this new `BarModel` data.

When you generate your new migration using the `--empty` flag, the file should end up looking something like this.

	::python
	from django.db import migrations, models

	class Migration(migrations.Migration):

		dependencies = [
				('myapp', '0011_auto_20190108_0750'),
			]

		operations = []

We can then add a `RunPython` operation to the `operations` list that execute a custom function.

	::python
	from django.db import migrations, models


	def create_bars(apps, schema_editor):
		...

	class Migration(migrations.Migration):

		dependencies = [
			('myapp', '0011_auto_20190108_0750'),
		]

		operations = [
			migrations.RunPython(create_bars)
		]

This means that the migration will execute the `create_bars` method when it is applied.

We can then fill our new `create_bars` function with something like this:

	::python
	def create_bars(apps, schema_editor):
		FooModel = apps.get_model('myapp', 'FooModel')
		BarModel = apps.get_model('myapp', 'BarModel')

		for foo in FooModel.objects.all():
			instance, _ = BarModel.objects.get_or_create(
				field_a=foo.field_a,
				field_b=foo.field_b,
				field_c=foo.field_c,
				field_d=foo.field_d,
			)
			foo.parent = instance
			foo.save()

So what does this function do? Well, we loop through all of our `FooModel` entries and we set its `parent` field to a newly created `BarModel` entry. Note that we use `get_or_create`, this means that we avoid creating multiple duplicate `BarModel` entries and we reuse them for many `foo` instances.

After this migration is run, we should have populated all required `BarModel` entries and our nullable `FooModel.parent` field should now all be populated. There should be no empty `parent` `ForeignKey` fields after this migration is applied.

### Finalize the State of our Models

At this point in time, all of our existing `FooModel` should point to a `BarModel` and even though the field is `null=True`, no entries should have a null value. This means that we are now ready to finalize the state of our models by updating it to its final version.

	::python
	class BarModel(models.Model):
		field_a = models.IntegerField()
		field_b = models.IntegerField()
		field_c = models.IntegerField()
		field_d = models.IntegerField()


	class FooModel(models.Model):
		field_that_is_updated = models.IntegerField()
		parent = models.ForeignKey(BarModel, on_delete=models.CASCADE)

As you can see from the code example above, we now removed `null=True` from the `FooModel.parent` field, and we also removed the old `field_x` fields on the `FooModel` model. This will obviously delete all those fields from the database, and we will lose that data, but since our previous custom migration already migrated the data to a new `BarModel` entry, we should now be safe.

At this point you should be able to generate your final migration file and then apply all of these migrations with the following commands:

	::bash
	python manage.py makemigrations
	python manage.py migrate

## Summary of adding new ForeignKey to Django

At a first glance, this approach might look a bit confusing. We wanted to create a new `ForeignKey` that is **not nullable**, but the first thing we do is to create a field that **is nullable**.

This is OK though, we are creating multiple migration files that gets executed and applied synchronously. This process takes just a few seconds to execute, so your field is in practice only nullable for a moment as the migrations are applied.

By doing this we end up with complete data without any missing entries, and our old data will still be usable with our new data structure.
