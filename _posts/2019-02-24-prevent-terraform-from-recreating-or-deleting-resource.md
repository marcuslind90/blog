---
layout: post
title: Prevent Terraform from Recreating or Deleting Resource
date: 2019-02-24 00:00:00 +0000
categories: docker
permalink: /@marcus/prevent-terraform-from-recreating-or-deleting-resource
---

Believe it or not, during the past few months I've managed to delete the database of this website not just once but twice (almost three!). Imagine that, how can someone be so clumsy to delete their whole database?!

Well, at least I've learned my lesson. Obviously, it wasn't that I just wrote `DROP DATABASE` or anything like it by accident, what actually happened was that I accidentally reprovisioned my database instance which recreated a fresh version with a new, fresh state. Ouch.

The worst part was that the first time it happened, I thought it happened because I misunderstood another feature of Terraform, so I ended up not fixing it properly and then a few weeks later it happened again. Believe me, I was laughing out loud when it happened the second time, fortunately, at this point, I was already confident about my backup schedule and the consistency of my data.
 
## When do Terraform Recreate Resources?

Terraform reprovision your resource as soon as the definition of it has changed. My first impression of this was that it meant that if I changed the `.tf` file of my resource, it would reprovision the resource, and if I didn't update my `.tf` file, it would leave it as it was.

This is only partly true. The full truth is that yes, Terraform will recreate your resource if you update its `.tf` file, but that is not the only thing that will cause Terraform to recreate the resource. It will also recreate the resource if anything that your `.tf` file **points to** also changes.

In my case, I had the following DigitalOcean Resource defitition

	::terraform
	resource "digitalocean_droplet" "db" {
		name = "db"
		image = "ubuntu-18-04-x64"
		region = "sfo2"
		...
	}

Notice that it points to use the Ubuntu 18.04 image. This image is stored with DigitalOcean and Terraform will pull it down and initiate my droplet with it whenever my droplets are created. But what happened to the minor version of Ubuntu? The current version of Ubuntu when writing this article is 18.04.2.

Actually, this image contains the minor version but we as developers do not need to explicitly set it. What this means is that the image itself will update whenever a new patch is released, and the hash of the image will update. This, in the end, means that even though I haven't updated the `image` value, the image itself might have been updated which would trigger Terraform to detect changes.

This is what happened to me twice, and each time Terraform recreated my database instance by deleting it and recreating a new droplet which meant that it lost all its state. Luckily I had set up daily backups and I did not miss or lose any data.

## Preventing Reprovision of Resource using Lifecycle Hooks

There are a few things you can do to prevent these things from happening.

- Disallow deletion of the resource.
- Be explicit and avoid computed values.
- Ignore changes to certain fields.

Obviously, some resources are more sensitive for recreation than others. Stateless services such as a web application or processing instance should be able to be deleted and recreated at any point in time, and you should not need to worry much about what happens if they get recreated.

Databases and other stateful resources are a completely different question. In this case we want to be extremely careful about accidentally deleting it, and we can achieve this by following the points lined out above.

### Disallow Deletion of Terraform Resource
The first step that you should do is to completely disallow any deletion of a resource. This solves most of the issue since if Terraform attempts to delete the resource, an error will be raised and it will stop applying its plan.

You can achieve this by using the `lifecycle` block within your resource.

	::terraform
	resource "digitalocean_droplet" "db" {
		lifecycle {
        		prevent_destroy = true
		}
	}

This will make sure that your resource **never gets destroyed**. The only way for you to destroy or recreate your instance is if you intentionally, manually remove this block to apply your new changes. This is a tag that you definitely should use on any stateful service or resource.

### Be Explicit with Terraform Resources

Even though you can prevent deletion of resources using the `prevent_destroy` attribute, you must still prevent Terraform from detecting changes to your resource. If not, you will just be faced with the error that informs you of your resource attempting to be destroyed.

One rule that you should follow is to avoid any dynamic, flexible or computed values within your resource definition for these lifecycle-sensitive resources. Try to be as explicit and clear as possible with things such as image name, region, resource name etc.

This will make sure that your resource definition doesn't accidentally change.

### Tell Terraform to Ignore Changes to Fields

The final thing to do is to tell Terraform to ignore any changes to some specific fields. In the case above with the Ubuntu image, there is nothing more to do than to point to the image to 18.04, we have no control over when this image is being updated by DigitalOcean. 

What we can do then, is to tell Terraform to ignore any changes to the image, so that any changes to it doesn't automatically trigger a reprovision of the resource.

This is yet another thing that you can define in the Terraform resource `lifecycle` block.

	::terraform
	resource "digitalocean_droplet" "db" {
		lifecycle {
			prevent_destroy = true
			ignore_changes = ["image", ]
		}
	}

By adding the `ignore_changes` parameter to the `lifecycle` block, we can tell our Terraform resource definition to ignore any changes to the `image` field. This makes sure that Terraform does not attempt to reprovision the resource whenever the image changes.

## Summary

These are the steps that I follow to make sure that my stateful resources that are provisioned with Terraform don't automatically get recreated by accident. This is a lesson learned the hard way, and I hope that this article helped you avoid repeating the same mistakes that I've done in the past.

