---
layout: post
title: Generate Python Unit Test & Flake8 Reports for JUnit
date: 2019-08-02 00:00:00 +0000
categories: python tests flake8
permalink: /@marcus/generate-python-unit-test-flake8-reports-for-junit
---

One of the core parts of your Continuous Integration Pipeline (CI) is often to generate reports that detail the status of unit tests, their coverage and reports covering the static analysis of the codebase.

Usually, CI/CD Pipeline tools such as Jenkins or CircleCI prefer the reports in a specific format, so that they can easily display the contents within their UI. This format is usually the "JUnit" format, which originates from the Java community.

This causes some issues for us in the Python community. Tools such as `flake8` which can generate a .txt report are not generated in the JUnit format, and the same goes for the normal test-runner used by  `unittest`. So how can we then generate these reports, or transform the existing reports into a format that CI/CD tools such as Jenkins or CircleCI will be compatible with?

## Generate a Flake8 JUnit Report

Flake8 is a great tool that provides static analysis of your codebase and reports any issues when it comes to formatting, styling, syntax, docstrings or type hints. It's a great way to catch any obvious errors before the code gets pushed into production.

Normally when using the tool in the command line using `flake8 src/`, the tool will simply output the report within the terminal. This is not very helpful for us when we want to read the output and display it in the UI of our CI Pipeline.

You could use the `--output-file` flag to redirect the flake8 output to a file, but that will not be in the JUnit format.

The solution? Use the pip package `flake8-junit-report`!

By installing `flake8-junit-report` with `pip` you can easily convert the output generated from `flake8 --output-file=flake8.txt` into a .xml file in the JUnit format. 

Run the commands in the following order:

    ::bash
    mkdir -p test-reports/flake8
    flake8 . --output-file=test-reports/flake8/flake8.txt
    flake8_junit test-reports/flake8/flake8.txt test-reports/flake8/flake8_junit.xml

Let's recap what these commands actually do:

1. We create a new folder to store our test-reports in case it does not exist yet.
2. We run the standard `flake8` tool but we redirect output to a `flake8.txt` file.
3. We convert our `flake8.txt` file into a `flake8_junit.xml` file with the correct JUnit format.

Voila, your static analysis is now saved to a format that your Continuous Integration tool will love to work with.

## Generate a Python Unittest JUnit Report
Next up is the normal unit test report that you might want to generate to be able to display the results of your test run within your CI/CD tool of choice. Normally this information is only output to the terminal, but you might want to save it in a more structured format.

You could route the output of the `python -m unittest` command by piping it with `| tee unittest.log` but that is still just the text output and it's not in a structured JUnit format that can be displayed within the interface of the tool of choice for your project.

Luckily for us, within this great python community there is always a solution! Install the `pip` package named `unittest-xml-reporting`.

The `unittest-xml-reporting` package consists of a `unittest` test-runner that generates the output as a JUnit (xUnit) .xml file, it's super easy to use and it even comes with special test runners to use with frameworks such as the [Django Web Framework](https://www.djangoproject.com/).

In the case of a normal python application you would use it in the following manner:

Either simply by calling it in the command line:

    ::bash
    python -m xmlrunner discover -t ./tests -o ./test-reports/junit

Or you could also make it part of a python script where you can have some additional flexibility:

    ::python
    if __name__ == '__main__':
        unittest.main(
            testRunner=xmlrunner.XMLTestRunner(output='test-reports'),
            # these make sure that some options that are not applicable
            # remain hidden from the help menu.
            failfast=False, buffer=False, catchbreak=False
        )

### Generate JUnit Test Report with Django
Unlike normal python projects, unit tests written in a Django project is normally executed with the `python manage.py test` command which is an internal Django management command. 

Luckily, the `unittest-xml-reporting` package comes with a Django TestRunner class out of the box and it's easy to just plug-and-play. 

Simply add the following lines to your `settings.py` file within your Django project:

    ::python
    TEST_RUNNER = 'xmlrunner.extra.djangotestrunner.XMLTestRunner'
    TEST_OUTPUT_DIR = './test-reports/unittest'
    TEST_OUTPUT_FILE_NAME = 'unittest.xml'

Each time you run the `python manage.py test` command, it will now use the `XMLTestRunner` and generate a JUnit report at `./test-reports/unittest/unittest.xml`. 

By following the steps in this article, you should now be able to see both your unit test output, and your flake8 static analysis output within your CI/CD tool of choice.
