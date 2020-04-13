---
layout: post
title: Should I use virtualenv or Docker containers with Python?
date: 2019-01-16 00:00:00 +0000
categories: docker
permalink: /@marcus/should-i-use-virtualenv-or-docker-containers-with-python/
---

What if you have two different projects on your machine that require two different versions of the same package with python? Normally in languages such as NodeJS or PHP this is not a problem you just write `npm install --save <package>` and it will install it in the `node_modules/` directory in your project folder, but can the same thing be done with Python?

## Python install packages with interpreter
When you install a package using `pip` it will install the dependency together with your interpreter, this means that if you have Python installed on your system and multiple different projects, each project will install all their dependencies together with every other project. Ouch, right?

You will run into this issue fairly quick with Python, but don't worry there's solutions to this! 

## Use Virtualenv for project specific interpreters
`virtualenv` (`pip install virtualenv`) is a tool that allow you to create a new python interpreter that is specific for your own project. This means that when `pip` install any dependency it will do so only for the project specific interpreter, not for the system wide on that is shared on the whole machine.

To use virtualenv you simply use the following commands:

```bash
# Install it system wide so it can be used anywhere.
pip install virtualenv
# Use virtualenv to setup a new interpreter within the envs/ folder
virtualenv --python=python3.6 envs
# Activate the new virtualenv
source ./envs/bin/activate
```

*Note that if you're on Windows you cannot use the `source` command. Instead you will have to run the .bat file at `./envs/Scripts/activate.bat`*

So what happens when you activate the virtualenv? It's very simple really, all it does is overriding your system's `PATH` environment variable to point the python binary to this new `envs/` folder.

You can test this in MacOS or Linux by typing `which python` before and after you activate your environment to see which binary the `python` command is using. When you're done with your virtualenv you can simply type `deactivate` in your terminal to get back to the original state.

Virtualenv solved a very important problem with Python, it allowed developers to isolate their python dependencies on a project basis, and prevent the dependencies from leaking between projects.  It's a core tool in python development and every programmer or software engineer that touch python code should be aware of how to use it and how it works under the hood.

The truth of the matter though is that personally, I don't really like virtualenv. I feel like it's a bit of a hacky way to solve this kind of issue and I prefer the way NodeJS does things by allowing you to either install things globally, or locally with their package manager.

You probably ended up on this article by searching on this topic, and that by itself illustrates that it's not as intuitive for developers as it should be, and especially not as intuitive as some other package managers for other languages.

My preferred way to handle this issue? With Docker containers!

## Use Docker to isolate Python dependencies
[Docker](https://www.docker.com/) is my absolutely favorite tool that I've added to my arsenal the last few years. No matter what type of project I work on it comes handy and it has both improved my development environment, and my deployment process by a lot.

This article is not a in depth guide of Docker, but what is Docker used for? Its used to containerize your application which also allows you to run your application's container side by side with other containers or applications, while keeping the code between the containers completely isolated from each other.

Each container can be thought of its own machine with its own OS and file system. What this means for us as Python developers, is that we don't mind installing our packages "globally" anymore, because the container will only be used for our specific application. We will never run 2 different applications inside 1 container that might have different dependency requirements.

Remember what the goal of Virtualenv was? It was to isolate dependencies between different applications or projects. This is exactly what Containers allow you to do as well, but on an even larger scale than just having different python interpreters.

## Should I use Docker and Virtualenv together?
One of my top answers on Stackoverflow has been on a question from a developer who's asking if he should be using virtualenv inside his Docker image and container. This idea probably comes from that he is so used to using virtual environments in his Python project so that now when he's transitioning to Docker he want to keep doing things the way he's used to.

The question that he should ask himself though is why he wants to do this. What is the goal of Virtualenv and what is the goal of Containers? When you spend a few moments thinking about this you realize that the whole point of using virtualenv is already covered by using containers.

If you decide to use virtualenv to create a copy of the system interpreter within your Docker container, it will not achieve anything at all, the final result will be exactly the same as if you were not using it. The dependencies are just as much, or as little, isolated from other applications after you used it as before you did.

It will also complicate your code. Other developers might come to your project later and be confused of why it's using "two layers" of dependency isolation. Keep things simple and stick to one of these options!

Personally I prefer the Docker way because I feel like it gives so much more value to me than just isolating python packages. I also feel like it's a "non-hacky" way to solve this issue.
