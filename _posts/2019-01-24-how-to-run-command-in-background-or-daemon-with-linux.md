---
layout: post
title: How to Run Command in Background or Daemon with Linux
date: 2019-01-24 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-run-command-in-background-or-daemon-with-linux/
---

What if you have a task that you want to be running at all times on your system, but you don't want to run it in a terminal manually, instead you want it to always be running in the background of your Linux environment. How would you achieve this?

This is a very common task that you might run into fairly quickly in the world of DevOps. For example, imagine that you need to monitor your database to make sure that it doesn't die. You might want to monitor it by testing the connection to it every 5 seconds **all the time, forever**. This is just an example of a background task and I'm sure that you with your creative mind can come up with other situations where it might be needed.

In the world of Linux and Unix, there are more than one way to achieve this. In this article, I will show you two simple ways that I prefer to define the tasks and executions that I want to be running as background jobs on my Linux machine. 

## Create Process with systemctl
`systemctl` is a command that you can use that allows you to control the Linux `systemd` services and processes that are being executed when you boot or startup your Linux operating system. It's a very neat little thing that makes it very easy for you to start, stop and restart a service that is running in the background.

It comes with a lot of services out of the box that you can find at `/etc/systemd/system/`. They are files that end with the `.service` file ending.

If we have some kind of custom process that we want to run using the `systemctl` tool we can very easily create our own `.service` file that determines how our command is executed, and then starts it using our `systemctl` command. Great, right?

So let's imagine that we have a script called `monitoring.sh` that monitors some remote service, and we want to make sure that this shell script is running at all times as a background job or daemon within our Linux system. We can achieve this by creating the following file that we would name `/etc/systemd/system/monitoring.service`

```bash
[Unit]
Description=Monitor Service for DB

[Service]
ExecStart=/path/to/monitoring.sh
Restart=on-failure
EnvironmentFile=/etc/environment

[Install]
WantedBy=multi-user.target
```

A lot of this is very self-explanatory, but let's go through each step of our file to be explicit about what each section and definition does:

- `Description=` is just the description of our service. It can be used in various places to inform the system or user what the service is doing.
- `ExecStart=` is the path to the shell script that we want to execute when the service starts. Make sure that this shell script has executable rights which you can add by running `chmod +x /path/to/monitoring.sh`.
- `Restart=` is the restart policy we want for our service. Since we always want it running, we want it to be automatically restarted even if it fails.
- `EnvironmentFile=` is the file that contains any Environment Variables that we want our service to have access to. In this case, I point it to `/etc/environment` which is the file that contains all of our system level Environment Variables.
- `WantedBy=` defines which other service we want to trigger the start of our own service. This is relevant if we use `systemctl enable` to make sure that our service is started on boot. 

After placing it in our `/etc/systemd/system/` folder we will now be able to start our service with the `systemctl` command with the following command:

```bash
systemctl start monitoring.service
```

Voila! Your service should now be running in the background. 

### Reading logs of our systemctl service
What if we want to read the `stdout` and logs of our `systemctl` service that we created in the previous section? We can easily do that using the command `journalctl`. 

`journalctl` allow us to read all the outputs of our services and we can even limit it to the specific service that we want to see, so that we can ignore all the others. Use the following command to see the output of our `monitoring.service`.

```bash
journalctl -U monitoring -e
```

- The `-U monitoring` flag defines that we want to limit the output to the monitoring service.
- The `-e` flag makes sure that we get to the end of our output. This can be useful if our service has already produced thousands of lines of output and we want to avoid having to scroll down past all of it to get to the end.

## Run a Background Task using Supervisor
The first example above illustrated how we can start a background job/service using `systemctl` which is on the system level. What about if we want to bundle automated tasks with our application?

For example, imagine that we have an application that wants to start a Celery Worker in the background that listens for messages on a message queue to process asynchronous tasks. This is obviously very tightly coupled to our application and we might want to add the creation of a background task as part of the application instead of having system administrators adding it on the Linux system.

We can do this using a popular python package called [supervisor](https://github.com/Supervisor/supervisor). The current official release of Supervisor is supported on Python2.7 which comes preinstalled on many Linux distributions. You can install it using `pip` in the following manner:

```bash
pip install supervisor
```

Note that the team behind Supervisor is striving towards support Python3 within the near future, so when you're reading this article the Python3 supported version might already have been released.

For now, if you want to install Supervisor for Python3 you have to install it directly from their Master branch on [their GitHub Repository](https://github.com/Supervisor/supervisor).

```bash
pip install git+https://github.com/Supervisor/supervisor
```

### Configure Supervisor to Run Background Task
After installing Supervisor we have to add a configuration file for it to read when its being executed. The configuration file will allow us to define all the services, tasks and jobs that we want it to keep running in the background of our system.

Supervisor gives you the ability to generate a default config using the command `echo_supervisord_conf`. You can write this directly to a file by the following bash command:

```bash
echo_supervisord_conf > supervisord.conf
```

This file will contain a lot of existing configurations, some of it active and some of it disabled. We now have to add our own custom section to it to tell it how to execute our job.

```bash

...

[program:celery]
command=celery -A tasks worker -B -Q celery
stdout_logfile = /tmp/celery.log
redirect_stderr=true
```

Let's quickly summarize what each line of the configuration does:

- `command` is simply the bash command that we want to execute to run our job. In this example I follow the example given previously in this section where we wanted to run a Celery Worker. You could replace this with any other command available in the system you're running on.
- `stdout_logfile` routes the `stdout` of our job to a log file.
- `redirect_stderr` redirects our `stderr` to `stdout`, meaning that any errors that are output to `stderr` will be part of our `stdout` stream and the log file that we defined.

### Running Supervisor with Custom Config
Finally when we're done with the configuration its time to actually run it all. The Supervisor package gives us a command called `supervisord`, note the `d` in the end. This is the command that we will use to execute our jobs.

We can start our Supervisor processes with the following command:

```bash
supervisord -c supervisord.conf
```

The `-c` flag informs the `supervisord` command the file path to the config file that we want to use. This config file could live anywhere within your application.

That's it! At this point, you should have the process that you defined within your `supervisord.conf` file being executed as a background task or daemon on the system!
