---
layout: post
title: How to Store Terraform State on S3 and Cloud
date: 2019-01-24 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-store-terraform-state-on-s3
---

Terraform is an amazing tool that allows you to keep track on the state of the infrastructure that is running at your Cloud Provider, and it uses this state to understand if it needs to update, tear down or provision new instances of the different pieces of your infrastructure.

So for example, the first time you run Terraform your state is empty. You don't have anything running at all. This means that Terraform will try to create everything that you have defined within your `.tf` files on the cloud from scratch. 

So how does Terraform keep track of the state? It doesn't query the provider and checks the state of each instance in real time, instead, it keeps it all in JSON format stored in a `.tfstate` file that by default gets created from wherever you decide to run your `terraform` commands.

## Sharing State Across Team Members
But what if you work in a team and everyone needs to have access to these state files. How do you share them between developers? Or what if you want to run your Terraform commands from a CI/CD Pipeline such as Jenkins, AWS CodePipeline, TravisCI or CircleCI? How would those tools get access to the state?

I've seen some individuals automatically commit the state into the repository whenever it changes. Personally, I don't like this option for multiple reasons. First of all the state might contain sensitive data and we might want to keep any secrets, credentials or sensitive information away from our repository for security reasons. 

Second of all, if we use a CI/CD Pipeline that deploys our application by using Terraform, and gets triggered by changes to the repository, then by making it commit the state to the repository will make the Pipeline trigger itself again, and again, and again in an infinite deployment loop. Ouch right? So the solution to that would be to manually create some kind of exceptions to your CI/CD Pipeline and now suddenly we added a lot of complexity to our application. Not good. 

Because of this, I instead prefer to store my state remotely instead of keeping it within my code base. This is actually the way [Terraform and Hashicorp recommend you doing it](https://www.terraform.io/docs/backends/index.html). It's a much more clean and simple solution to a relatively simple problem. 

You could use Terraform Enterprise which is their paid solution that will help you out with some things like sharing state between team members. But in this article, I will show you how to set up your own storage solution where you store the state on S3 storages such as AWS S3 or DigitalOcean Spaces.

## Terraform Remote State Storage in Cloud
The way we define a remote backend is by simply setting the `terraform.backend` definitions within our root `main.tf` file.

	::terraform
	provider "digitalocean" {
		token = "${var.do_token}"
	}

	terraform {
		backend "s3" {
			bucket = "MY_BUCKET_NAME"
			key = "terraform/terraform.tfstate"
			region = "us-east-1"
			endpoint = "https://ams3.digitaloceanspaces.com"
			skip_credentials_validation = true
			skip_get_ec2_platforms = true
			skip_requesting_account_id = true
			skip_metadata_api_check = true
		}
	}
	
As in most cases when we use tools that integrate with the S3 Protocol, the settings seem to be very focused and targeted towards Amazon Web Services S3 Storage. Note that its not just Amazon that use S3 as a protocol, DigitalOcean Spaces which is what we're using in this example also uses it.

So what do we do here?
- We define a `backend` named `s3`.
- `bucket` is the name of our DigitalOcean Spaces space, or our AWS S3 Bucket
- `key` is the path to our state file.
- `region` is only used by AWS S3 and its the region of where we have created our S3 Bucket.
- `endpoint` is the URL that our Backend will send its communication requests to. In this case, we define it to our regional URL for DigitalOcean Spaces.
- `skip_` options are all things that are tightly coupled with Amazon Web Services that we need to disable for it to work with DigitalOcean Spaces. Remember, it's using the same Protocol but all settings might not be relevant.

Finally, we also have to provide the credentials of our application. We don't want to hard code them into our code and expose the secrets so we want to store them as Environment Variables, but you can't inject variables and use them from within your `backend` block because Terraform runs the backend block before it initiates the variables. 

So how do we achieve this then? Luckily for us, the `terraform init` command allows us to define backend config parameters using the `-backend-config` command options.

	::bash
	terraform init -backend-config="access_key=$ACCESS_KEY" \
	     -backend-config="secret_key=$SECRET_KEY"
 
 This would be exactly the same as writing it within the backend block, but it allows us to use Environment Variables from the system level instead.
 
 At this point your integration should be working and by running the `terraform init` command it should connect to your S3 instance and initiate the state files there. Now every time changes are being done, it will read and write the updates to the remote storage that will be used no matter from where you execute the `terraform` commands. 
 
This means that now you can execute things locally, in a CI/CD Pipeline or from your team members computer and each time it will share the same information of the state of your infrastructure.

## Why should I use Terraform Enterprise?
Storing the state remotely in the cloud has worked great for me for all the projects that I've used Terraform on. I've never experienced any issues, but I am well aware of the fact that this custom solution might not give us as many benefits as the paid [Terraform Enterprise](https://www.hashicorp.com/products/terraform) solution does.

So what are we missing that Terraform Enterprise would offer us?

- Locking state while updating.
- Remote Execution of long-running changes.
- History of changes to the state.
- Secure variable management.

Let's go through each one and see if this is something that we feel is a priority for us or not.

### Locking Terraform State
So imagine that Terraform is part of our repository and we're sharing all of our code base with a team of many developers. What would happen if we do changes to our infrastructure at the same time as another developer in our team? Each time we run Terraform it might take minutes or maybe even hours (in complex systems) for it to complete.

We would end up with broken states that get modified by multiple different sources. That would not be a very pleasant thing to attempt to solve if we ever get stuck in that situation.

One way of preventing these things from happening would be to only execute the Terraform commands through a CI/CD Pipeline. By doing this we can control the flow of the executions instead of having some kind of free-for-all within our team where anyone could do anything at any time. 

Note that this doesn't guarantee that the problem will not occur, but it gives you the control required to prevent it.

### Remote Executions of Terraform Apply
Throughout all the projects that I've worked on with Terraform, I've only managed about ~10 application instances at the same time. The deployment to these 10 instances goes fairly quickly and I'm able to provision it all in just a few minutes. 

But what if you're working on a project where the infrastructure is massive and provisioning it might take hours? Maybe you don't want your CI/CD Pipeline to be blocked for such a long time, or if you're running Terraform locally from your computer you probably don't want to keep your terminal open for all that time. 

This is where Remote Executions comes in. With Terraform Enterprise you can let them execute the changes to your infrastructure remotely, without having to wait for it to complete on your side.

This is hardly something that is relevant for most small to medium sized projects. But if you're working in an Enterprise environment this could be a game changer.

### History of State Changes
What if the changes to your infrastructure messed things up and you want to return to a previous state. How would you achieve that? With Terraform Enterprise, it will help you keep track on the complete history of any changes to the state so that you easily can rollback to a previous version of your state.

Once again, in an Enterprise environment when changes might be common, this could be a great way to keep track of things and to rollback. In my own experience, I haven't felt the need for it yet.

### Secure Variable Management
Your Terraform State might contain a lot of sensitive information within them. You definitely don't want anyone to have access to it due to security reasons. If you're using Terraform Enterprise, not only are you storing the state remotely to keep it away from other people's eyes, but you can also strip away and censor any kind of private, secret or sensitive data from the state.

I personally feel that with a proper setup with S3 you can achieve pretty good security without the need to literally censor the data itself. Make sure that its only the CI/CD Pipeline that have access to the state files, and that by itself should be good protection from giving people access to your secret credentials.

## Final Thoughts of Custom Storage vs Terraform Enterprise
Terraform Enterprise can definitely be a great solution for you to manage remote state and collaborate between team members for anyone who works in a large company with complex infrastructure. 

For me, I still haven't felt the need to use the paid solution and instead I prefer to reuse the S3 instances that I'm already using for my applications for general media storage, to also store the Terraform State. 

Unless you have some very specific needs, I feel that storing the state on your own remote storage is secure enough, and by executing it in a CI/CD Pipeline it helps enough to make sure that the state is not being updated from multiple different sources at the same time.
