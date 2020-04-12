---
layout: post
title: How to start a Django Project with Docker
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-start-a-django-project-with-docker
---

How do you setup a new Django project with Docker while following the best practices and making sure that your local development environment stay as close as possible to your production environment?

In this article I share step by step how I setup new Django projects with Docker and Docker Compose that use a PostgreSQL database instead of the standard SQLite database.

The only prerequisite you need for this is to have Docker installed on your computer.

## Initiate your Dockerfile and Requirements
Let's get going with our project. The first thing we do is to setup our repository and our project folder locally on our computer.

	::bash
    mkdir project
	// Either clone an existing repository...
	git clone https://github.com/<user>/<repo>/ project
	cd project
	// or init a new repistory
	cd project
	git init
	
	touch docker-compose.yml
	
	mkdir src
	cd src
	
	touch Dockerfile
	touch .env
	touch .envexample
	mkdir requirements
	touch requirements/base.txt
	touch requirements/dev.txt
	touch requirements/prod.txt
	
We then edit `Dockerfile` and add the following content:

	::yml
	# The base image we want to inherit from
	FROM python:3.7
	ENV PYTHONUNBUFFERED 1
	ARG ENV=dev

	RUN mkdir /app
	WORKDIR /app
	ADD ./requirements /app/requirements
	
	# Install the pip requirements file depending on 
	# the $ENV build arg passed in when starting build.
	RUN pip install -Ur requirements/$ENV.txt
	
	# Copy the rest of our application.
	COPY . /app/
	
	# Expose the application on port 8000
	EXPOSE 8000
	# Run test server
	CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

We also edit our `/requirements/base.txt` file and add 

    ::bash
    django>=2.1.4
	psycopg2-binary>=2.7.6.1

*There might be more recent version of these packages out when you're reading this article*

We also edit our `/requirements/dev.txt` and `/requirements/prod.txt` files with the line `-r base.txt` which means that they both will inherit all content from the `base.txt` file that we defined above.

So let's go through what we're doing here:

1. Our Dockerfile accepts a build argument called `ENV` that define for which environment we want to build the image for. Depending on what argument we pass in, we will install the dependencies from different pip requirement files such as `dev.txt` or `prod.txt`. This allow you to customize which packages gets installed in your Production environment or your Development environment.
2. We make sure that we add the Requirement files **before** we add any of our other content to our image. This is to take advantage of Docker's Caching mechanism. It means that as long as we do not update our pip requirements, we that step will be cached and the only thing we do for a re-build is to copy all the project files into the image.
3. We expose port 8000 which is the normal port that Django runs the test server on, and then run the Django test server using the `python manage.py runserver` command.

### Storing Credentials as Environment Variables
As you can see from the steps above, we created `.env` and `.envexample` files in our project. These files are suppose to hold the environment variables that we want our containers to use so that we can rely on them always being specified when we run our project.

The reason why we want to store credentials and other settings as environment variables is because of two reasons:

1. We don't want to expose secret credentials! Our code should always read in credentials from environment variables and they should never be hardcoded into our code and commited to our repository. Any credential such as a secret key or a password should therefor be specified inside our `.env` file.
2. We want easily be able to change configuration values between environments without having to redeploy our code. Imagine that we want to change a database hostname, debug mode or the file path on some S3 storage? If these things are stored in environment variables we can separate configurations between Dev, Staging and Production easily while still keeping the code identical.

The reason we have the `.envexample` file is because this one will be commited into our git repository and hold all the names of the environment variables that is required. It is used as a template for other developers to see what they have to define when they create their own `.env` file.

## Setup Docker Compose file with PostgreSQL container

Before we build our project we also want to create a Docker Compose file that describe all the containers of our application. We do not want to use the default sqlite database, instead we want to use PostgreSQL which we plan to run as a separate container next to our main Django Application container.

Edit your `./docker-compose.yml` file in the root of your project folder and add the following content to it:

	::yml
	version: '3'

	services:

		app:
			build: ./src
			restart: always
			env_file:
				- ./src/.env
			ports:
				- "8000:8000"
			volumes:
				- "./src/:/app/"
			command: bash -c "python manage.py migrate --no-input &&
							               python manage.py runserver 0.0.0.0:8000"

		db:
			image: postgres:9.6
			restart: always
			volumes:
				- "./volumes/db:/var/lib/postgresql/data"

So let's go through what all this does shall we?

1. We define 2 types of containers, an `app` container which builds our `./src` folder where our `Dockerfile` is located, but then also a `db` container which is based on the `postgres:9.6` image.
2. In both of our containers we set `restart: always` which means that if the container crashes and exits, Docker will automatically try to restart it. 
3. In the `app` container we specify an `env_file`. This file is a normal text file that contain all the Environment variables that we want to be set within the container.
4. In the `app` container we map the exposed 8000 port to the local 8000 port. This means that we will be able to access the container on `localhost:8000`.
5. In the `app` container we map our `./src` folder to our containers `/app` work directory. This means that any changes to the files locally on our computer, will automatically be updated and synced with the files inside our containers. This makes sure that we do not have to rebuild our image every time we have done changes to our code.
6. In the `app` container we override the `CMD` command inside the Dockerfile to also migrate our database migrations when the container is started.
7. In the `db` container we map the PostgreSQL data volume to our own local `./volumes/db` folder. This means that the state of the container is stored locally on our computer so that it does not lose state each time we recreate the database container. If we would not do this, then the database container would be fresh/empty every time we tried to run it.

## Instantiate our Django Project
Finally its time for us to create our Django project. We will simply do that by typing `docker-compose run app django-admin startproject project` in our terminal while we're located in the root of our project folder.

When you do this you will see that a `manage.py` file was created within your `./src` directory and you now can see a `project` folder in there that contain your Django project.

So how did all this work? What did that command actually do? Let's split up the command in multiple parts to get a clear understanding of what we're actually doing.

`docker-compose run app <command>`

The first part `docker-compose run app` means that we want to use `docker-compose` to run a container specified within our `docker-compose.yml` file. Since we use the default name of the file the command will automatically pick it up.

The second part which was `django-admin startproject project` is the actual command that we run within the image. This command overrides both the command typed within the `Dockerfile` and the command written within the `docker-compose.yml` file. What it does is using the `django-admin` tool to run the command `startproject` to generate the project files inside the `project` folder.

Since we mapped the `./src:/app` volumes in our `docker-compose.yml` file it means that when the command was executed inside our container, the files created was also mapped out to our local `./src` folder.

Now when your project was created you should be able to run it by typing `docker-compose up` which will start the server, and then you should be able to visit it at `http://localhost:8000`.

### Setup Settings to use PostgreSQL
When you ran your containers with the command described in the previous part, you were still using the SQLite database that comes with Django by default. We plan to use PostgreSQL in production and to emulate our production as closely as possible, we should also use it locally on our computer.

Do you remember that we created an `.env` and `.envexample` file in the first step of this article? These are the files that store our Environment Variables and this is where we will store the credentials to our PostgreSQL database. Since we define the `env_file` option in our `docker-compose.yml` file, it means that our container will automatically read in the file and define these environment variables inside our container.

Add the following Environment Variables to your `.env` and `.envexample` files:

	::bash
    RDS_DB_NAME=postgres
	RDS_HOST=db
	RDS_PORT=5432
	RDS_USERNAME=postgres
	RDS_PASSWORD=

All of these settings are what the PostgreSQL Docker image use by default, the only thing that might be different in your case is the `RDS_HOST`. This is the host name of our database and it should be the name of our database container. In our case we named it `db` inside our `docker-compose.yml` file.

Since these settings are the "default" values, they are hardly a secret and we should therefore also store them in our `.envexample` file which will be checked into our repository so that other developers easily can get going with running our containers.

**Note that we never want to store real secrets within our git repository. You should only add ENV vars to your .envexample file if they are not secret credentials**.

Finally we also want to go into our `settings.py` file to change our database backend from SQLite to PostgreSQL. If you've followed this guide correctly the settings file should be inside `./src/project/settings.py`

Go to the `DATABASES = {}` section and set it to the following:

	::python
	DATABASES = {
		'default': {
			'ENGINE': 'django.db.backends.postgresql',
			'NAME': os.environ.get('RDS_DB_NAME'),
			'USER': os.environ.get('RDS_USERNAME'),
			'PASSWORD': os.environ.get('RDS_PASSWORD'),
			'HOST': os.environ.get('RDS_HOST'),
			'PORT': os.environ.get('RDS_PORT'),
		}
	}

It will use the `os` library (which is imported into the settings file by default) to read the systems environment variables and use them as string values for our `DATABASES` configuration. 

You should now be able to re-run your container with the following commands:

	::bash
	docker-compose down --remove-orphans
	docker-compose up
	
Voila, now you have a Django project using a PostgreSQL database running with Docker.


## Before Pushing, add a .gitignore
Now we're done and its time to push our project to our git repository. Before we do that we should add an `.gitignore` file to our repository to make sure that we do not commit anything we don't want to keep!

I like to use [Gitignore.io](https://www.gitignore.io/api/python,django) as a base for my `.gitignore` file but then extend it by using a few custom rules:

	::bash
	envs/  # VSCode directory where it auto finds virtualenvs 
	/volumes  # We don't want to checkin our DB volume
	/src/media  # We don't want to checkin our Django media files
	/src/static  # We don't want to checkin our Django static files
	.vscode/  # The VSCode config directory
	
After you've added your `.gitignore` file you should be able to push your changes to your repository with:

	::bash
	git add .
	git commit -m "Initial commit"
	git push
    