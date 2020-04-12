---
layout: post
title: How to Split and Organize Terraform Code Into Modules
date: 2019-01-24 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-split-and-organize-terraform-code-into-modules
---

Terraform is one of my favorite tools that I picked up last year and part of why I like it is the ability to organize your infrastructure as code into readable, logical chunks of digestible code that any developer can lookup and easily understand within a quick glance.

Before I started using IaC (Infrastructure as Code) tools such as Terraform I was defining all of my infrastructures within the dashboard of the cloud provider that I was using for the project (Usually Amazon Web Services or DigitalOcean). In my opinion, this quickly became messy and it was difficult to have a good understanding of what parts of the infrastructure that I had deployed at any given point in time.

At some point, I even forgot that I had some instances running on Amazon Web Services that kept charging my credit card money for things that I wasn't even using... Ouch, right?

You can then understand my joy when I started using Terraform and I found a tool that allowed me to organize my infrastructure into modules, and that allowed me to keep track on what my infrastructure looked like, even if I came back to the project months later.

## Modularizing Terraform
I feel like one of the most common mistakes we software engineers do when we start learning a new tool, is to trade off all the best practices that we know of, with trying to learn the tool quickly. 

We know that we should split things into readable modules, but as we go along reading the tutorial we just want to get to the next step so we end up dumping all of it into this huge file that we would never allow ourselves to do if we worked on a real, production project.

So after I've done the same mistake myself, and dumped all of my definitions into a single `main.tf` file, it was time to refactor it into something that is usable and that I could share with fellow colleagues without having to be ashamed of my huge block of code.

### Suggested File Hierarchy
For the web project I was working on, I transitioned from the following file structure:

	::bash
	./terraform
		main.tf
		
To my improved file structure:

	::bash
	./terraform
		./web
			droplet.tf
			firewall.tf
			loadbalancer.tf
			main.tf
		./db
			droplet.tf
			firewall.tf
			main.tf
		main.tf
		
Just by giving the file hierarchy itself a good look we went from having no idea what the `main.tf` file contained, to suddenly having a great insight into what parts our infrastructure consists of just by looking at the folder and file names.

Hopefully, this illustrates the usefulness of splitting your Terraform code into modules, but this also comes with some new requirements. Instead of expecting any kind of variable to be available anywhere, we now have to make sure that state and variables are passed in, or exported to and from each module that needs the information.

### Defining the Modules And Passing Variables
So let's start off with our root `./terraform/main.tf` file. This file by itself will not contain any resources, instead, it will just import and define all of the input variables and the modules that we want to use. 

	::terraform
	variable "do_token" {}
	variable "pvt_key" {}
	variable "ssh_fingerprint" {}
	
	provider "digitalocean" {
		token = "${var.do_token}"
	}
	
	module "web" {
		source = "./web"
		pvt_key = "${var.pvt_key}"
		ssh_fingerprint = "${var.ssh_fingerprint}"
	}
	
	module "db" {
		source = "./db"
		pvt_key = "${var.pvt_key}"
		ssh_fingerprint = "${var.ssh_fingerprint}"
	}
	
So lets talk about what we are doing here. Obviously, this is just an example and for our example, we use the `"digitalocean"` provider to provision resources in the cloud at DigitalOcean.

- We start off by defining 3x `variable` that we expect to be provided when calling our Terraform `terraform plan` and `terraform apply` commands. These variables are required by our DigitalOcean provider to be able to provision resources.
- We define the `provider` to be using DigitalOcean and we set the required DigitalOcean token.
- We define 2 modules, `web` and `db` that we then point to each corresponding directory. The `web` module point to the `./web` directory, and the `db` module point to the `./db` directory. Finally, as you can see, we also pass in the variables required for DigitalOcean to provision resources for both of those modules, to make sure that they are available within each module.

## Defining Variables within Terraform Modules
In the previous section, we could see how our root `main.tf` file define modules and then pass in the required variables to each of those modules. For each of our module to be able to accept those variables, we have to define them as `variable` within each module's own `main.tf` file.

So let's take the `web` module as an example. In `./terraform/web/main.tf` we have to add the following definitions:

	::terraform	
	variable "pvt_key" {}
	variable "ssh_fingerprint" {}
	
By doing that it means that we can now access the values passed in as `"${var.pvt_key}"` or `"${var.ssh_fingerprint}"` from anywhere within our `web` module.

## Accessing Values from Other Terraform Modules
So we now know how we define variables within our modules and how we can pass the values into them. But what if you want to access a value that is created from within a sibling of a module?

For example, what if our `web` module need to get the IP Address of the Droplet that was created from within our `db` module so that our application within the `web` droplet can connect to the database?

### Exporting Variables from Terraform Modules
We can do this by exporting the value from the `db` module back to the root `main.tf` file, and then pass it into our `web` module just like we did with the other variables.

The magic thing about this is that Terraform will automatically infer this dependency and make sure that the `db` module creates its resources first so that it has access to the IP Address value that it exports, that the `web` module later takes advantage of. All of this happens automatically and you don't need to worry about having to define these dependencies explicitly.

So how do we export the IP address then? We go to our `./terraform/db/main.tf` file and we add the following definition:

	output "db_ip" {
		value = "${digitalocean_droplet.db.ipv4_address}"
	}
	
As you can see from the code, what it does is that it exports the `db_ip` variable and it sets it to the value of the `digitalocean_droplet` resource named `db` and its attribute called `ipv4_address` which represents its private IP address. Note that all of this is specific to the DigitalOcean provider and if you use any other provider these definitions will be different to your particular use case.

If we then go back to our `./terraform/main.tf` file we can now access this exported variable as `"${module.db.db_ip}"`. So we can then pass it into our `web` module by adding another line of variable definitions to it:
	
	::terraform
	module "web" {
		source = "./web"
		pvt_key = "${var.pvt_key}"
		ssh_fingerprint = "${var.ssh_fingerprint}"
		db_ip = "${module.db.db_ip}"
	}
	
Then obviously inside our `./terraform/web/main.tf` file we also have to add the `variable` definition of `db_ip` so that the module itself knows that it should expect it as an input.

	::terraform
	variable "pvt_key" {}
	variable "ssh_fingerprint" {}
	variable "db_ip" {}
	
We can now access the value as `"${var.db_ip}"` from anywhere within our `web` container.

## The Magic of Terraform Inferred Dependencies
At this point, we have shown you how you can refactor your Terraform definitions from being in a single file where everything has access to everything else, to instead splitting your definitions up into modules. You can then choose to only pass in the variables that each module require for it to provision the declared resources, which makes things more explicit and easy to understand for any other developer who might come along.

One of the things that makes this so simple and easy to use is Terraform's way to automatically infer the dependencies that each resource or module has, and then make sure that everything gets executed and provisioned in the right order.

There's something that you have to be aware of though, and that is circular dependencies.

### Circular Dependencies between Terraform Modules
So imagine that we have the same infrastructure definitions as we mentioned on top, but instead of just the `web` module being dependent on the `db_ip` exported value from the `db` module, we also had a reverse dependency where the `db` module depended on some information from the `web` instance that was created.

What would Terraform then choose to execute first? The `db` module or the `web` module? Well, it would all result in a crash and an error because Terraform wouldn't be able to make that choice.

This is something that you have to keep in mind when using values from other modules and resources. You have to make sure that no 2 resources depend on each other. If you experience this issue there is no "magic fix". You have to break the dependency yourself.
