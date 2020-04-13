---
layout: post
title: A complete guide to CI/CD Pipelines with CircleCI, Docker and Terraform
date: 2019-10-14 00:00:00 +0000
categories: circleci docker terraform devops
permalink: /@marcus/a-complete-guide-to-cicd-pipelines-with-circleci-docker-and-terraform/
---

Setting up a Continuous Integration and Continuous Delivery pipeline has become something that every project requires from the start these days to enforce high-quality code. I see it in all kinds of projects no matter if it's for the web, data science, machine learning and so on.

With a CI/CD pipeline, you can enforce that any code that gets merged to your release branch and deployed into your production passes all tests and checks that you have configured such as unit tests, integration tests or linter checks.

A lot of guides out there will give you minimum examples to allow you to quickly get going. But what about a real, production pipeline using common open-source tools used for larger projects? In this guide, we will cover the complete pipeline required to deploy new code to this website that you are reading this article on.

The technologies that we will rely on will be:

- CircleCI
- Docker
- Packer
- Terraform
- DigitalOcean
- Ansible

We will use all of these technologies to test, build and deploy a Python application.

Don't worry if you are not using all of these tools within your specific application or pipeline, you can still learn a tremendous amount from this guide and skip any steps that you do not depend on. Also, this guide is still relevant no matter if you are using Python or not.

## High Overview of our DevOps Pipeline
Our pipeline will be using [CircleCI](https://circleci.com/) as a CI/CD Platform. CircleCI is free to use and is one of the most common platforms to use. They also offer an enterprise version that allows you to self-host the software on your own instance if you want to be in full control -- something that is quite common within larger businesses.

The pipeline will include the following steps:

1. Install Python Dependencies.
2. Run flake8 lint checks to identify easy to catch syntax errors.
3. Run unit tests.
4. Create JUnit test coverage reports.
5. Build a Docker Image and push it to the registry.
6. Build a machine image at DigitalOcean using Packer.
7. Use Terraform to build and update DigitalOcean infrastructure with the latest machine image.

## Prepare our CircleCI config
CircleCI understands the pipeline that it should execute based on the CircleCI config that you provide within your git repository. This config should be stored within `.circleci/config.yml`. It is simply a YAML file that defines each step to be executed.

The initial config to start of with for our case will be:

    ::yaml
    version: 2

    jobs:
        build:
            working_directory: ~/workspace
            docker:
                - image: circleci/python:3.6.4
                   environment:
                       RDS_DB_NAME: circleci
                       RDS_HOST: localhost
                       RDS_PORT: 5432
                       RDS_USERNAME: root
                       RDS_PASSWORD:
                - image: circleci/postgres:9.6
                   environment:
                       POSTGRES_USER: root
                       POSTGRES_DB: circleci
        steps:
            - checkout

All we are doing here is setting up the environment required for us to run our pipeline on. In our case, we are testing this specific website which depends on a PostgreSQL database and a Python 3.6 image.

A few things to note:

- The `working_directory` is where our code repository will live.
- The first image defined is the image that will be used to execute our code and our pipeline. The order of the images defined matters.
- We run our tests against the real type of database that we use in production, we do not replace the usage of PostgreSQL with something like SQLite just because it is "easier". We want our tests to run against something with a low discrepancy to production.
- We follow the [12 Factor App](https://12factor.net/) and define all our configuration such as hostnames, passwords, and usernames as environment variables within our codebase. This easily allows us to point the database used by the code to this temporary PostgreSQL container.
- The `steps` key will be where we list all the steps of our pipeline. In this case, we simply include the `checkout` step which will clone our code into the Python Docker image defined to be used.

## Install our Python Dependencies
In the case of my pipeline, I split up the dependencies required for my application to run and the dependencies that are required for me to deploy my application. This makes the dependency installation slightly faster since the ones required to run the application are installed every time, while the one required for deployment is only installed when the `master` branch is updated.

To install the dependencies, I add the following to my `steps` key. Note that the `...` is simply there to shorten the code example and hide the other steps that have already been defined.

    ::yaml
    steps:
        ...
		run:
	        name: Install dependencies.
                command: sudo pip install -Ur requirements.txt

As mentioned above, this `requirements.txt` file includes all my `pip` dependencies that are required to lint, test and run my application.

## Run Flake8 Linter and Store Results in Test Report
After installing our dependencies it is time to do our first checks. The first thing we will do (because its usually one of the fastest and will error our early if something is wrong) is to lint our codebase using `flake8`. 

A linter is a static analysis tool that allows us to easily catch simply errors such as styling mistakes, syntax errors or logical errors such as passing in the wrong type of variable into a function that expects something else.

    ::yaml
    steps:
        ...
        run:
            name: Run linter.
            working_directory: ~/workspace/src
            command: |
                mkdir -p test-reports/flake8
                flake8 . --output-file=test-reports/flake8/flake8.txt

There are multiple things to note about this section:

- We override the `working_directory` to run the command from a subfolder of our repository. This has simply to do with how my specific repository is structured and I want to avoid running the linter on other folders of my codebase.
- We use a pipe symbol `|` in our `command` section which allows us to give a multiline input to execute two separate commands.
- We use `mkdir` to create a new directory to hold our test report from the `flake8` command. This is required if we want to later display the lint errors neatly within CircleCI instead of the console.
- We run `flake8` using the `--output-file` option where we define the path of where we want to store the output. Note that we also namespace the report using a `/flake8/` folder name. This helps with presenting the report within CircleCI in a more neat manner.

## Run Unit Tests and Generate JUnit Test Report in Python
Next up is to run our unit tests. The unit tests do usually take longer than running the linter, which is the reason why it is the second thing we do within the pipeline.

We could of course just run our unit tests using the normal `python -m unittest discover .` command, but one of the main reasons why we use a proper CI/CD Pipeline Tool such as CircleCI is to allow us to neatly, in a human-readable format, display any issues so that anyone in our team can quickly understand what is going wrong with a build -- no matter how technical they are.

If we want to neatly display any errors on issues within CircleCI we have to store the Python Unittest results in a test report following the JUnit format. This is unfortunately not natively supported within Python.

Luckily, there is a great package named `unittest-xml-reporting` [PyPi](https://pypi.org/project/unittest-xml-reporting/) that allows us to do this. The package itself contains a test runner that we use to run our test suite, and it will automatically generate the report for us.

The package can be executed to run any tests, but it also got a nice integration with Django and its `./manage.py test` command which I am taking advantage of.

Make sure that you install it using `pip` and make sure that your test suite is executed with its test-runner. 

On top of that, we also want to generate a coverage report that informs us of the total test coverage of our codebase. This will be done using the popular `coverage` [package](https://pypi.org/project/coverage/).

After making sure that both of these dependencies are installed and included in our `requirements.txt` file, we simply run it (with Django's build in management test command) with the following definition:

    ::yaml
    steps:
        ...
		run:
			name: Run tests.
			working_directory: ~/workspace/src
			command: coverage run manage.py test

Within our Django config, we define that the test report is stored within `./test-reports/unittest` folder which just like the `flake8` output is namespaced with a `/unittest/` folder. 

## Generate JUnit Flake8 Reports and Coverage HTML Reports
After we have executed our linter, and ran all of our tests, it is now time to finalize the test report output. The unittest report is already formatted within the JUnit format, but the flake8 output is still plain text, and we have still not generated anything from our `coverage` command.

    ::yaml
    steps:
        ...
		run:
	        name: Create Test Reports.
            working_directory: ~/workspace/src
            command: |
				flake8_junit test-reports/flake8/flake8.txt test-reports/flake8/flake8_junit.xml
				coverage html -d test-reports/coverage
			when: always

By using the tool `flake8-junit-report` ([PyPi](https://pypi.org/project/flake8-junit-report/)) we can convert the plain text output that we stored earlier in the `flake8` step into JUnit XML format. Note that we store it within the same folder namespaced with `/flake8/`.

We use `coverage html` to generate HTML output based on whatever was executed with the `coverage run` command that we executed in the previous step. Once again, we make sure to namespace it with the `/coverage/` subdirectory.

After this step, we have not generated the following reports:

- JUnit Unit Test Report.
- JUnit Flake8 XML Report.
- HTML Coverage Report.

Note that we also write `when: always`. This means that this step will execute no matter if our pipeline is a success or a failure. If a step fails it will **always** make sure that the reports get generated, which allows the developer to always inspect and understand what went wrong.

Finally, to make sure that our pipeline actually uploads and store these reports so that they can be viewed after the pipeline has finished executing, you must add the following steps to the bottom of your pipeline.

    ::yaml
    steps:
        ...
        - store_test_results:
                path: myapp/test-reports

        - store_artifacts:
                path: myapp/test-reports
                destination: tr1

## Setup SSH Keys and Docker Commands in CircleCI Pipeline
The steps so far have been things that we want to execute with every branch that has commits coming into it. We always want to lint and test our code. Next up will be steps related to packaging, building and deploying our application. This will only be done on the `master` branch.

To prepare for those steps, it is now time to install any dependencies that are required for this.

First of all, make sure that you add the following steps to the top of your `steps` list.

    ::yaml
    steps:
		- checkout

        - setup_remote_docker:
                docker_layer_caching: yes

        - add_ssh_keys:
                fingerprints:
                    - 97:72:82:74:n2:29:12:fa:3f:hd:fk:14:a2:63:6c:ec

The `setup_remote_docker` command simply enables us to use Docker commands such as `build`, `push`, `login` in future steps.

The `add_ssh_keys` is a crucial step that allows us to include SSH Keys in our pipeline that are required for us to later communicate with the nodes that exist within our infrastructure. Note that the fingerprint string must be added manually within the CircleCI dashboard to be able to be imported/added in this manner.


## Installing Dependencies such as Terraform, Packer, Ansible and Docker in CircleCI
Next up is installing the rest of the programs that must exist on our instance to allow us to use the tools required for us to package and deploy our application.

These tools are:

- Terraform
- Packer
- Ansible
- Docker

Docker and Ansible can be installed using `pip` and since we are already running our pipeline in a python Docker image, this is incredibly easy with a `pip install ansible docker` command.

Unfortunately, Terraform and Packer are not as easy to install and instead it requires us to manually download the executables and unpack them on our instance. Because of this, I decided to put that logic in a separate shell script.

The final step that installs the dependencies are:

    ::yaml
    steps:
        ...
		run:
			name: Install Deployment Dependencies.
			command: |
 	           if [ "${CIRCLE_BRANCH}" == "master" ]; then
					sudo bash resources/dependencies.sh
					sudo pip install ansible docker
				fi

Note that we wrap the command in an if statement that makes sure it only executes on the master branch.

The script `dependencies.sh` look like the following:

    ::bash
    #!/bin/bash
    set -e
    CIRCLECI_CACHE_DIR="/usr/local/bin"
    PACKER_VERSION="1.4.2"
    PACKER_URL="https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    TERRAFORM_VERSION="0.12.10"
    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

    if [ ! -f "${CIRCLECI_CACHE_DIR}/packer" ] || [[ ! "$(packer version)" =~ "Packer v${PACKER_VERSION}" ]]; then
        wget -O /tmp/packer.zip "${PACKER_URL}"
        unzip -oud "${CIRCLECI_CACHE_DIR}" /tmp/packer.zip
    fi

    if [ ! -f "${CIRCLECI_CACHE_DIR}/terraform" ] || [[ ! "$(terraform version)" =~ "Terraform v${PACKER_VERSION}" ]]; then
        wget -O /tmp/terraform.zip "${TERRAFORM_URL}"
        unzip -oud "${CIRCLECI_CACHE_DIR}" /tmp/terraform.zip
    fi

    packer version
    terraform version

Just to quickly summarize what the `dependencies.sh` script actually does:

- Define a bunch of constants that allow us to easily change things such as the Packer or Terraform versions in the future.
- The first if statement checks if Packer is installed, if not then it pulls it down using `wget` and then unzips it into `/usr/local/bin` which is part of the executable `PATH`.
- The second if statement checks if Terraform is installed, if not then it pulls it down using `wget` and then unzips it into `/usr/local/bin` which is part of the executable `PATH`.
- Print out the Terraform version and the Packer version just to verify that the installation was successful.

## Build, Tag and Push Docker Image with Ansible in CI/CD Pipeline
After we have installed all the dependencies required, it is finally time for us to start building our application to prepare for it to be deployed in the cloud. To do this, we will build it into a Docker Image using Ansible.

To achieve this, we add the following step to our `steps` list:

    ::yaml
    steps:
        ...
        - deploy:
                name: Building, Tagging and Pushing Docker Images
                command: |
                    if [ "${CIRCLE_BRANCH}" == "master" ]; then
                        ansible-playbook resources/packer/ansible/build.yaml
                    fi

All it does is that it runs our `build.yaml` playbook if we are on the master branch. Note that we use `deploy` instead of `run` to make it explicit that its part of the deployment.

The playbook itself looks like this:

    ::yaml
    - name: Build, Tag and Push Docker Image from Local folder.
        hosts: 127.0.0.1
        connection: local
        roles:
            - app-build

As you can see from the playbook, the `hosts` and `connection` keys make sure that the playbook is executed locally. It is not reaching out to any remote instance.

The `app-build` role look like this:

    ::yaml
    {% raw %}
    - name: Login to Docker
       docker_login:
            username: "{{ lookup('env','DOCKER_USERNAME') }}"
            password: "{{ lookup('env','DOCKER_PASSWORD') }}"
    {% endraw %}
    - name: Build Docker Image
       docker_image:
            build:
                args:
                    ENV: prod
                path: ./../../../src
                pull: yes
            name: myuser/myapp
            source: build
            state: present
            tag: latest

    - name: Generate git commit hash
       command: git log -n 1 --format="%h"
       register: commit_hash

    - name: Tag and push image with commit hash
       docker_image:
            name: myuser/myapp:latest
            repository: "myuser/myapp:{{ commit_hash.stdout }}"
            push: yes
            source: local

    - name: Push image with latest tag
       docker_image:
            name: myuser/myapp
            tag: latest
            push: yes
            source: local

Let's walk through the full ansible role together:

- Login to our private Docker Registry which allows us to both pull and push to it in the following commands. The credentials are stored as environment variables that are set in the CircleCI dashboard.
- We build the Docker Image. The `path` is simply the backward path to get to our `src` directory where our `Dockerfile` exists. In your case, it might be a bit different. The `name` is the name of our image.
- We do not want to store all of our Docker images as `:latest` tag, instead we want to version them properly. We do this by tagging each image with a subset of its commit hash using the `git log` command which outputs the latest commits hash value. We store this in the `commit_hash` variable.
- We tag the existing image that we just built with the new commit hash and we push it to the Docker Registry.
- We push the existing image that we built with the `latest` tag to the Docker Registry.

Now we've done with building our application and it is time to prepare to actually deploy it.

## Generate a Packer Machine Image at DigitalOcean in Continuous Delivery Pipeline
Next up is to prepare our cloud machine image that will be the base of each compute node at DigitalOcean. This will be done using Packer.

Why do we want to create a machine image and not just use some script that SSH into the instances and update them? Well, Terraform works by identifying changes to its plan and then updating the infrastructure to match these changes. 

In theory, you could manually `tint` nodes to force them to be rebuilt and to pull the latest image, but a more natural way of doing it is to simply update the machine image of each node itself, and make Terraform automatically recognize that the state has changed and then apply the changes required to match the clouds state with its Terraform definition.

This is done using the following step added to our `steps` list:

    ::yaml
    - deploy:
            name: Building Packer Image
            working_directory: ~/workspace/resources/packer
            command: |
                if [ "${CIRCLE_BRANCH}" == "master" ]; then
                    packer build -machine-readable web.json | tee web.log
                    echo "export PACKER_IMAGE_ID=$(grep 'artifact,0,id' web.log | cut -d: -f2)" >> $BASH_ENV
                fi

Here we have some quite interesting things going on that took quite a while to figure out:

- We change the `working_directory` to our packer folder to make sure that the commands get executed in the correct context.
- We use `packer` to build our web.json machine image definition and we pipe it to `tee web.log` to save all the output to a file. Note that we use the `-machine-readable` flag to make it easier to parse the output later.
- We use `grep` to extract the newly created DigitalOcean Droplet ID and store it in the `PACKER_IMAGE_ID` environment variable. This ID is crucial to store to later tell Terraform which version to deploy.
- Note that we actually use `echo "..." >> $BASH_ENV` to store our environment variable. This is because of CircleCI's limitation. We can not define environments directly, instead, we have to add it to the `$BASH_ENV` which will be sourced/read later and then the ENV will be defined.

The `web.json` Packer file is unique for each project, but all mine includes is `ansible` provisioner that pull down and run our Docker Image that we created in an earlier step.

## Use Terraform to Provision Packer and Docker Image on DigitalOcean in CircleCI Pipeline
Finally, we have come to the stage where we are ready to deploy the actual application. So far we have just tested and built our application -- and it has been quite a lot of work to get it right.

Luckily, by using Terraform with our prebuild Packer image, it will be very easy to achieve rolling deployments of our infrastructure and get our new version of our application up and running in the production environment without any downtime. All we have to do is to tell Terraform that our Droplet ID has changed.

The two last steps simply apply `terraform init`, `terraform plan` and `terraform apply` which means that it informs DigitalOcean to update any infrastructure that does not match the Infrastructure as Code definitions. 

    ::yaml
    steps:
        ... 
        - deploy:
                name: Terraform Init and Plan
                working_directory: ~/workspace/resources/terraform
                command: |    
                    if [ "${CIRCLE_BRANCH}" == "master" ]; then
                        terraform init -force-copy -input=false
                        terraform plan \
                            -var "web_image_id=${PACKER_IMAGE_ID}" \
                            -var "pvt_key=${HOME}/.ssh/id_rsa_97728274n22912fa3fhdfk14a2636cec"
                    fi

        - deploy:
                name: Terraform Apply
                working_directory: ~/workspace/resources/terraform
                command: |    
                    if [ "${CIRCLE_BRANCH}" == "master" ]; then
                        terraform apply \
                            -auto-approve \
                            -var "web_image_id=${PACKER_IMAGE_ID}" \
                            -var "pvt_key=${HOME}/.ssh/id_rsa_97728274n22912fa3fhdfk14a2636cec"
                    fi

Note the following things about these steps:

- We inject the `web_image_id` variable from the `PACKER_IMAGE_ID` variable that we set earlier in the packer build step. This ID is referred to in the Terraform web server droplet defintion. When this value is changed (in each build) Terraform forces new droplets to be provisioned.
- We inject the `pvt_key` variable to be the path of our SSH key required to communicate with our DigitalOcean infrastructure. This SSH key was added because of the `add_ssh_keys` step that we defined at the top of our `steps` list. Note that the file name is based on the fingerprint but without any colons (`:`).

## Conclusions and Summary
As you have noticed by following this guide, it is quite an extensive pipeline that takes quite a lot of work to setup. However, it does cover everything from A-Z when it comes to testing, linting, building and deploying your application.

There are multiple things that can be improved upon this pipeline such as:

Implement caching to avoid having to install dependencies on each run.
Remove the if statements that check for the branch and use the native CircleCI syntax instead.
In case there is no need to actually store the Docker Image in a Registry, perhaps the Docker Build step could be ignored and everything could be done in the Packer step. 

Do you have any other ideas on how this pipeline could be improved?