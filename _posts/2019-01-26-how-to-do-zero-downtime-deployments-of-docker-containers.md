---
layout: post
title: How to do Zero Downtime Deployments of Docker Containers
date: 2019-01-26 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-do-zero-downtime-deployments-of-docker-containers/
---

Green and Blue Deployments, or Zero Downtime Deployments is a hot topic that is relevant for any DevOps Engineer. It's the discussion of how we can update our application without causing any disturbance to the user experience while we're doing it. 

I love using Docker and it has been one of the most amazing tools that I've adapted to my workflow within the last few years. In almost all of my projects I use Docker Compose to define my containers, and whenever I have a new update I just use the following command to recreate my updated container:

```bash
docker-compose up -d
```

The `up` command will instantiate your containers, but on top of that, it will also recreate the containers if anything has changed, like its tag. So if I update my `docker-compose.yml` file to run `myapp:v2` instead of `myapp:v1` it will automatically pull down the latest update and recreate the container with it by using `docker-compose up`. 

Last year I was working on a project, and one day one of the product owners messaged me on Slack and jokingly said "Ah I see that the new version is coming out! I can notice the site is updating". In her mind, this was a fun thing but personally, I felt "Oh shit!". The user should never be able to see that the website is being deployed or updated. Something was wrong.

## Docker Containers Go Down While Recreating
The issue was that while Docker is recreating the container, the whole container dies for a few seconds. This might just happen for a very short amount of time, and if you're deploying rarely for a minor private website, perhaps that's okay. But as a professional who works with global enterprises, I was not satisfied with that type of behavior of my deployment process.

So the question is then, how do I update my containers without bringing down the website while doing so? How do I achieve "Zero Downtime"? The answer is, "Green Blue Deployments".

## What are Green/Blue Deployments?
Green and Blue Deployments is the process of keeping the current version of your application running and serving requests to the users, while you in simultaneously set up your new version in the background. Then when your new version is ready to accept traffic, you redirect all traffic to it and then tear down the old version.

This means that during your deployment you have 2 versions of your application up and running at the same time, one we call the "Green" and the other we call the "Blue".

### Green Blue Deployments on Server Level or Container Level?
As you can see from the description of Green/Blue Deployments in the previous section, it is just a pattern of how you do your deployment. It doesn't go into exact details of how you implement this, and that means that there are many correct ways to do it, that all achieve the same goal which is the Zero Downtime Deployment.

In this article I will show you how we can do this on the Container level, meaning that we spin up a new container while we keep our old container running and serving requests, and then only after our new container is completely up and running, we tear down the old one. 

Another alternative could be to do all of this on a higher level of our infrastructure. Instead of spinning up a new container, we could spin up a completely new server instance that we deploy and then by using load balancing we can redirect traffic from our old server to our new server and then tear down the old one.

Both of these alternatives follow the same pattern and achieves the same goal. The method you choose might depend on what tools you have available and what fits you the best. There is no "right" or "wrong" answer.

## How to Recreate Containers with Zero Downtime
So let's get going with creating our Docker Deployment which will recreate our containers in parallel and achieve the Zero Downtime Deployment that we are striving for. 

We need to do the following things:

- Setup a new container while the old container is running.
- Wait until the new container is completely ready.
- Use Load Balancer to send traffic to the new container.
- Remove the old container.

### Initiate our Example Files
For the same of giving a clear example, let's start by setting up a file structure and initiate some Docker files. 

```bash
./
    /app
        app.py
        wsgi.py
        requirements.txt
        Dockerfile
    docker-compose.yml
    deployment.sh
```

In this case the `/app` folder contains a simple Flask application that is served with Gunicorn and is exposing Port 8000. The Dockerfile look like this:

```Dockerfile
FROM python:3.6
ENV PYTHONUNBUFFERED 1

RUN mkdir /app
WORKDIR /app
ADD requirements.txt /app/
RUN pip install -Ur requirements.txt
ADD . /app/
EXPOSE 8000
CMD [ "gunicorn", "wsgi:app", "-w", "6", "--bind", "0.0.0.0:8000" ]
```

The `docker-compose.yml` file is the Docker Compose file that defines how our containers are being created. For now, we will just initiate it with the following content:

```yml
version: '3'
services:
    app:
        build: ./app
```

Finally the `deployment.sh` file will contain the commands that will deploy our container. 

### How to Setup 2 Containers Side By Side
So the first step of our Green/Blue Deployment process was to be able to set up two containers side by side. We want to be able to set up a new container while our old one is still running. 

This can actually very easily be done using the `docker-compose --project-name` flag. By using that flag we can have a "Green" and a "Blue" project up and running at any time.

Try it out with the following commands:

```bash
docker-compose --project-name=green up -d
docker-compose --project-name=blue up -d
```

We can properly implement this with our `deployment.sh` script with the following bash script:

```bash
#!/bin/sh
if [ $(docker ps -f name=blue -q) ]
then
    ENV="green"
    OLD="blue"
else
    ENV="blue"
    OLD="green"
fi

echo "Starting "$ENV" container"
docker-compose --project-name=$ENV up -d

echo "Waiting..."
sleep 5s

echo "Stopping "$OLD" container"
docker-compose --project-name=$OLD stop
```

Let's summarize what this script actually does:

- We run an if-statement that checks if any `blue` containers are running. Based on if blue containers exist or not, we set the `$ENV` and `$OLD` environment variables accordingly.
- We start the new container.
- We wait a fixed amount of time to allow our new container to bootstrap properly. This number might need to be adjusted depending on the specifics of your application.
- We stop our old container.

You can test this script right now and check your containers with `docker ps` and see how they get rotated around, and around and around. It goes from Blue to Green to Blue to Green.

### Use Traefik Load Balancer to Send Traffic to Containers
After we have created a method that will spin up a container in parallel with our old container, we now need to implement a Load Balancer that will send the requests to the right container depending on its state.

There are many different load balancers out there. A lot of people enjoy using Nginx for this, but unfortunately, Nginx does not have automatic container discovery. It does not automatically know when a new container is created and ready to accept traffic. Because of this, we will use the amazing load balancer called [Traefik](https://traefik.io/).

The first step we will do is to set up a dedicated Traefik container on our system. This container should always be running and it should not be tightly coupled with our application. Because of this, I will define it in its own `docker-compose.traefik.yml` file that we will run independently. 

```yaml
version: '3'

services:
    traefik:
        image: traefik
        networks:
            - webgateway
        ports:
            - "80:80"
            - "8080:8080"
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - ./traefik.toml:/traefik.toml

networks:
    webgateway:
        driver: bridge
```

A few things to note about this Docker Compose file:

- We use the official Docker Hub Traefik image.
- We set up a custom network called `webgateway`. Our Traefik container and our application containers need to be on the same network for them to be able to communicate with each other.
- We map 2 ports. Port 80 is where we will accept our normal traffic and send it to the containers. Port 8080 is the port that we will serve Traefik's Dashboard from. This is only used during development, we can remove it later.
- We mount the Docker Socket so that Traefik have access to the containers running on our system.
- We mount a custom `traefik.toml` configuration file.

#### The Traefik Config
As you could see from the Traefik Docker Compose file, we are mounting a `traefik.toml` file into our container that holds the configuration for our Traefik load balancer. The configuration file should be populated with the following content:

```toml
defaultEntryPoints = ["http"]
logLevel = "DEBUG"

[api]
address = ":8080"

[entryPoints]
    [entryPoints.http]
    address = ":80"

[retry]
attempts = 3
maxMem = 3

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "localhost"
watch = true
exposedbydefault = false
```

Let's summarize each and every one of these configuration values:

- `defaultEntryPoints` the default entry point that is used when the frontends (the containers that we route traffic to) does not define their own. This means that we expect traffic to be send over HTTP to our containers.
- `logLevel` sets the log level for the Traefik container.
- `[api]` creates a dashboard that is available on port 8080. Here you can overview all the containers that Traefik has identified. It also allows you to debug and find issues with your load balancing. It can be a great tool during development.
- `[entryPoints]` defines the address that we are routing traffic on. In this case all traffic that comes in on port 80.
- `[retry]` defines how many times the load balancer should retry the routing. This is crucial for our use case, if you don't define this then the user might be met by errors if it tries to route traffic to a container that is about to be shut down while Traefik is still sending requests to it.
- `[docker]` defines our Docker settings for Traefik.

#### Running Traefik
As I mentioned earlier in this article, Traefik is expected to be running on our system completely independent from the rest of our application containers. Because of this, we will run it as a separate `--project-name`.

You are supposed to start the Traefik container with the following command:

```bash
docker-compose --project-name=traefik -f docker-compose.traefik.yml up -d
```

Traefik should always be running on our system, no matter which application version that is up and running at any given time.

#### Configure Our Application Containers to use Traefik
Now when our Traefik Load Balancer is up and running we have to make some slight adjustments to our original `docker-compose.yml` file that holds the container specifications of our application containers, so that they accept traffic from Traefik in the correct way.

First of all, remember that we defined a special network that Traefik runs on? We also have to make sure that our application containers run on that network.

```yml
version: '3'
services:
    app:
        build: ./app
        networks:
            - traefik
networks:
    traefik:
        external:
            name: traefik_webgateway
```

The next step is to add Docker `labels` to the container to inform Traefik of how the container is supposed to be used. Remember, Traefik automatically discovers containers. Because of this, we do not configure the containers behavior within Traefik, because Traefik doesn't know from the start which container that it will need to interact with.

Instead, the configuration of each container that Traefik is sending traffic to, is done on the container side by using Labels.


```yaml
version: '3'

services:
    app:
        build: ./app
        labels:
            - "traefik.enable=true"
            - "traefik.backend=flask_app"
            - "traefik.backend.healthcheck.path=/health"
            - "traefik.backend.healthcheck.interval=1s"
            - "traefik.frontend.rule=Host:localhost"
            - "traefik.port=8000"
        networks:
            - traefik

networks:
    traefik:
        external:
            name: traefik_webgateway
```

That's our final and complete Docker Compose file for our application container. Let's quickly summarize those labels and what they do.

- `traefik.enable=true` enables traefik load balancing to the container.
- `traefik.backend=flask_app` simply gives a label/name to our container that can be seen from the Traefik API Dashboard. Useful for debugging and identifying containers.
- `traefik.healthcheck` activates healthchecks to our container. This is very important and it helps us avoid sending traffic and requests to the containers before they are initiated and ready.
- `traefik.frontend.rule`  defines the path that we are expected to be able to use to access our container on.
- `traefik.port` defines the port that the container is listening on. Remember that we used `EXPOSE 8000` in the Application Dockerfile?

That should be it! At this point, you should be able to have Traefik running on your system and then run your `deployment.sh` file to deploy new containers without having any distruption. You have now achieved Zero Downtime Deployments!
