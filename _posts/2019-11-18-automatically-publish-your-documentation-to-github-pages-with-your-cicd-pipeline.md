---
layout: post
title: Publish your documentation to GitHub Pages from Jenkins Pipeline
date: 2019-11-18 00:00:00 +0000
categories: jenkins devops documentation github-pages
permalink: /@marcus/automatically-publish-your-documentation-to-github-pages-with-your-cicd-pipeline
---

A proper documentation is a must have for any project that is expected to be shared or handed over to someone else in the future. Personally, in all of my professional projects I stress the importance of starting with a documentation from the start of the project and populating it as we go along, instead of treating it as an afterthought and fill it out in the end before client handover.

Some people leave their documentation as README files in their repository, this becomes a problem to manage very quickly since it makes it quite difficult for the reader to search and browse the documentation properly, a better, more sustainable and professional solution is to write your documentation using [Sphinx](http://www.sphinx-doc.org/en/master/) which allow you to create a proper website that looks beautiful and allows your readers to consume your documentation in a user friendly manner.

## Hosting your Sphinx Documentation
A website must be hosted somewhere, and it can be a pain to have to setup a web server and host it on just for every project you work on. It becomes quite a large barrier of entry and it leads to developers skipping out on writing and hosting their docs, because they don't want to pay and maintain a running server to host it on. 

Luckily, during the last few years there has been a few services popping up such as [Read the Docs](https://readthedocs.org/) which allow you to host your public repository documentation for free. Something that you've probably seen used by many of your favorite open source projects. 

But perhaps you don't want to leverage a public platform like Read the Docs, perhaps you have a private, internal project that you want to host documentation for. Well, why not use [GitHub Pages](https://pages.github.com/)?

GitHub Pages allow you to host your documentation right from your git repository. It requires no extra services or infrastructure other than your GitHub project which you are probably using anyway. It also work very well with GitHub Enterprise.

### How to host your documentation using GitHub Pages?
So how do GitHub pages work? Does it force you to keep the build version of your documentation in your repository (ugh)?

If you go into the "Settings" tab of any GitHub Repository you will see a section for "GitHub Pages". Here you can set the "Source" and one of the options are "gh-pages branch". 

The "gh-pages" branch is a special branch detached from the HEAD of your repository that can contain only your build files of your documentation. This branch will never merge in Master, and it will never be merged into Master either. It's a completely separated branch that only contain your documentation -- not your application.

By setting the source to "gh-pages branch", GitHub Pages will automatically load in all the HTML, CSS and JavaScript files from that branch and publish it on your GitHub Pages URL to display your documentation.

Sounds hacky? Well it kind of is, but it works pretty well!

## Use the NodeJS "gh-pages" Package to Manage your gh-pages Branch

One problem with the above approach of hosting your build files within a "gh-pages" branch is that it can be quite a pain to manage a branch that is completely detached from the HEAD. You have to make sure that any file from your master branch is deleted and that it only contains the build. It can also be quite a pain to manage all of this from a Continuous Integration pipeline. 

Luckily others have had to deal with this problem before and there exists a `gh-pages` CLI tool that can be installed using `npm` that allows you to easily publish your build folder to your "gh-pages" branch and push it to your repository. 

Simply run the following to build your Sphinx documentation located in the `docs/` folder and then deploy your documentation to GitHub pages using the `gh-pages` CLI.

    npm install -g --silent gh-pages@2.1.1
    cd docs/ && make html
    gh-pages --dotfiles --message '[skip ci] Updates' --dist docs/build/html

For sphinx documentations it is crucial that you include the `--dotfiles` option to make sure that any CSS and JavaScript is deployed and loaded properly.

That's it, the `make html` command is part of Sphinx and builds your documentation to the `build/html/` folder while the `gh-pages` command takes care of commiting and pushing the files to your `gh-pages` branch. The `[skip ci]` message is a common pattern to use to force your CI tool to ignore the new commit so it does not recursively keep building your documentation.

## Publishing to GitHub Pages from Jenkins Pipeline
Now we know how to build our documentation and publish it manually using the `gh-pages` CLI. How do we automate this and make it part of our CI/CD Jenkins Pipeline so that our documentation is updated every time our `develop` branch is changed?

If you are working with a NodeJS application it is pretty straight forward, just install the NPM package and run the command. But what if you are building for example a Python application? In that case your Jenkins Agent will not come preinstalled with either NodeJS or NPM and it would instead have to be installed manually.

This is how I write my Jenkinsfile to auto publish my GitHub Pages docs.

    pipeline {
        agent {
            dockerfile {
                filename "Dockerfile"
				dir "app"
            }
        }

        stages {
            stage("Build Docs") {
                steps {
                    sh "pip install docs/requirements.txt"
					sh "cd docs/ && make html"
                }
            }
            stage("Deploy Docs") {
                steps {
                    sh "curl -sL https://deb.nodesource.com/setup_12.x | bash -"
                    sh "apt-get update && apt-get install -y nodejs npm"
                    sh "npm install -g --silent gh-pages@2.1.1"
                    sh "git config --global user.email 'ci@jenkins.com' && git config --global user.name 'ci-auto'"
                    sh "git config --global credential.helper '/bin/bash ${WORKSPACE}/ops/credentials-helper.sh'"
                    sh "gh-pages --dotfiles --message '[skip ci] Updates' --dist docs/build/html"
                }
                when {
                    branch "develop"
                }
            }
        }
    }

This Jenkinsfile expects the following:

* Our real application are within the `/app` folder of our repository and contain a `Dockerfile` which we use as an agent for Jenkins. This Dockerfile do not contain NodeJS or NPM since it is not expected to be part of our applications requirements other than generating the Documentation.
* Our documentations are within the `/docs` folder and is using Sphinx.
* We have an `/ops/credentials-helper.sh` file that contain a simple script that allow us to set our GitHub credentials to give Jenkins access to push to our repository (See more below).

The way the Jenkinsfile work is:

* For every commit it will deploy our documentation. This is important to make sure that the build process of the documentation was not broken on any branch. As you can see from the "Build Docs" stage, it is installing any requirements related to building the documentation from a separate `requirements.txt` file than from the rest of the application. This is done because our application itself (the Dockerfile) do not require these dependency to be executed, and therefore we only include the dependencies from within the Jenkins job, not within the application itself.
* We build our documentation from the `docs/` folder using the `make html` command that use the build in make file generated by Sphinx.
* We deploy our application only on commits to the `develop` branch, this is set by the `when { branch "develop }` block.
* Since our application is not a Node application, we must install NodeJS and NPM. This takes a few minutes but since it is not done on every build I consider it acceptable.
* It configures `git` within the Jenkins job so that it have access to push to our git repository.

Note that I am using a `credentials-helper.sh` script, I found that this was an easy way to set any git credentials properly from the command line. I was struggling with providing them inline. Perhaps you can share if you were able to do that yourself!

The `credentials-helper.sh` file is very simple and only contains the following code:

    #!/bin/bash
    echo username=$GIT_CREDS_USR
    echo password=$GIT_CREDS_PSW

The credentials themselves are added from within the Jenkins Credentials manager named "GIT_CREDS" which automatically sets the `GIT_CREDS_USR` and `GIT_CREDS_PSW` environment variables. All the script does is setting the git credentials that are required to push to the repository.

That's it! Your Jenkinsfile should now be building and publishing your documentation to GitHub Pages automatically every time you commit to your develop branch.
