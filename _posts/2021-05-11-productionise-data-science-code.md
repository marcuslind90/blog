---
layout: post
title: Productionise your Data Science or Machine Learning code
date: 2021-05-11 00:00:00 +0000
categories: python, data science
---

My current role as a Lead AI Engineer usually revolves around leading teams of data scientists to productionise and scale their models so that they can be applied for larger datasets, more markets and
be democratised and used more easily by more members within their company. 

Sometimes I come into the team at a point where there already is a Proof of Concept living in a Jupyter Notebook somewhere, and other times I'm part of the team from day 1 when we start on a new Data Science or Machine Learning model or solution.

During the past few years when I've surrounded myself with Data Scientists and AI Projects, I learned a few important things to prioritise when I want to take a Machine Learning project into production that I wanted to share with you today.


## Structure application as a pipeline (DAG)

One of the first thing we want to do is to ensure that our ML project is structured as a DAG (directed acyclic graph) or in plan English, a pipeline consisting of steps or "tasks".

For example, a pipeline could consist of the following steps as an example:

* Load and transform data.
* Identify underperfoming products.
* Run forecast model on those products.
* Optimize changes based on forecasts and add business constraints.
* Format output and send to third party system.

By breaking apart our application into multiple smaller "tasks" or "steps" we will quickly gain multiple benefits such as:

* Easier to organize our team resources and assign people to work on independant tasks.
* Makes our codebase much more readable, organized and easy to understand for new members.
* Our application becomes modular and we can for example iterate/replace our "Forecaster" without
  having to touch the rest of our application.
* Enables usage of tools such as [Airflow](http://airflow.apache.org/) and other pipeline tools.

Finally, one important detail that I like to enforce when structuring the application like this, is to never pass in-memory data between the different tasks or steps. For example, we don't want Task A to return an object that is passed into our Task B.

The reason for this is because if we avoid this pattern, we can later on more easily use distributed computing and run different tasks on different servers/machines that might not share the same file system.

For example, Task A might run on Server A och Task B might run on Server B. This kind of architecture is not always required, but it is always useful to keep this possibility open for when day come to scale our application to larger datasets and heavier compute. By ensuring that there are no "in-memory dependencies" between the Tasks, this makes it much more easier to scale in the future.


## Validating Incoming and Outcoming Datasets and Dataframes

To ensure that our project runs stable for long periods of time, we have to ensure that our dataframes contains the data that we actually expect. There has been plenty of times in my own career where upstream data is changed from one day to another which could cause strange behavior in our model unless its caught early.

The approach I like to do is to do similar to what the Web world do with their frameworks such as Django or tools like SQLAlchemy. I like to create a "Schema" that defines exactly what structure
that the data is expected to follow, and then ensure that its validated against this schema every time the data is read or being written.

For example, you could use [pandera](https://pandera.readthedocs.io/en/latest/dataframe_schemas.html) to define Schemas that automatically validates your Pandas dataframes every time you load it.


```python

import pandera as pa

from pandera import Column, DataFrameSchema, Check, Index

schema = DataFrameSchema(
    {
        "column1": Column(pa.Int),
        "column2": Column(pa.Float, Check(lambda s: s < -1.2)),
        # you can provide a list of validators
        "column3": Column(pa.String, [
           Check(lambda s: s.str.startswith("value")),
           Check(lambda s: s.str.split("_", expand=True).shape[1] == 2)
        ]),
    },
    index=Index(pa.Int),
    strict=True,
    coerce=True,
)
```

Now when we are using this schema every time we load our data, we will fail quickly if the data has changed and if something is wrong. This is much better than getting invalid output that might "look correct" and be used in production even though it was produced on invalid datasets.


## Abstracting model parameters to configuration files

Making the Data Science application perform well on large datasets is not the only thing that is important when we are talking about "scaling" machine learning applications. Making the application "easy to use" is at least equally important. If its not used, it provides very little value.

Configuration management is one of things that fall into this bucket of "making things easy to use". Users might want to run the application on different markets, different datasets, different training periods and they might want to experiment with different weights and parameters on the model.

If all of these things are hardcoded in the application, it requires a Software Engineer to update the code each time the end user want to try to run it with any of these scenarios. It is therefore very important that we abstract these parameters into a configuration file that is easier to manage than Python scripts. 

Personally, I enjoy working with YAML files as a configuration format but it could also be done using Database tables, JSON, Web API endpoints etc. Sometimes a combination of formats can be used, for example you might load user modified parameters from an API and load "defaults" from a YAML file.

I usually try to support the following types of configurations:

* A configuration checked into the repository that is versioned. This configuration holds all "Defaults".
* Configurations stored outside the repository on e.g. S3 storage. These configurations could be partial configurations that contain parameters for specific use cases such when running on a certain month, a certain market, a certain product category etc.
* Patch values that can be added when triggering the model. E.g. we might run our model using a CLI command, and we might want to easily experiment by tweaking parameters in the CLI call itself. For example, ``python run.py pipeline --patch country=US``.


## Use a Cloud Storage like S3, Blob Storage or GCS

Plenty of data science and machine learning proof of concepts live on someones laptop or perhaps on a single virtual machine. In situations like this, one of the key limitations is data storage and how much data you can store on that single machine.

One of the lowest hanging fruits that allows you to scale to use larger datasets and store multiple versions of your outputs would be to use a cloud storage file system like Amazon S3, Azure Blob Storage or Google Cloud Storage. These storages can scale infinitely and you will never run out of storage space. It's a small investment, easy to implement and has a high payoff.
