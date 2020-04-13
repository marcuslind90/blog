---
layout: post
title: How to Write Unit Tests and Mock with Pandas
date: 2019-08-02 00:00:00 +0000
categories: python tests pandas
permalink: /@marcus/how-to-mock-and-unit-test-with-pandas/
---


I'm spending a lot of my time working close to data scientists where I review their code, give feedback and attempt to guide them to follow the best software engineering practices. The point is to make sure that our projects have scalable, robust and well-tested code.

I was recently working on a project where I immediately pulled down the code repository that the data scientists were working on to run the tests locally, and to my surprise, I noticed that most of the tests were failing. Why? Apparently, the test suite could only be executed from one specific remote server due to all the dependencies that the tests had.

## Create an Independent Test Suite
The test suite of a project might need to be executed on a number of different places. You might execute it locally to make sure that the changes you're working on do not break existing functionality, it might be executed as part of your continuous integration pipeline, or it might be executed on some remote server.

When it comes to Unit Tests, the intention of them is to test small "units" of code and to make sure that each isolated function returns and execute what is expected.

This is different from Integration Tests or Functional Tests where you might want to test a number of different functions of code together and see how they are working with other services or applications.

Since a Unit Test is supposed to be an "isolated unit of code", it means that the code should be able to run itself without relying on external services or system, including expectations of what is on the file system. Any services or files loaded by the code should be "mocked" so that the unit test can run without relying on it. This will result in an independent test suite that can be executed anywhere.

## Why you should Mock Files and Queries
"Mocking" is the concept of replacing a real call to something (could be code, a file, a hive query, a database query etc) with a fake, pre-defined response. This results in the following benefits:

* You do not rely on the external code or service.
* You speed up your test. It does not need to do IO or Computations that are outside the scope of the test.
* You can predict the response. If the code generates random values, uuids, timestamps etc, you can make turn those responses into static, predetermined values.

Some developers get confused by this, how can we ensure that a function that queries a database is working as expected if we hardcode the response of the query? Well, the point of our unit test isn't to test if the database connection is working, if the table exists or if the ORM that you're using is able to construct the SQL query in a valid way. All those things should be tested by separate unit tests.

All you care about is the logic that is within the "unit" of code that you are testing.

## Mocking Pandas in Unit Tests
The python `pandas` library is an extremely popular library used by Data Scientists to read data from disk into a tabular data structure that is easy to use for manipulation or computation of that data. In many projects, these `DataFrame` are passed around all over the place.

I've seen a bunch of times where developers "mock" these things by placing actual files on the file system that they then read in. This is a terrible idea for multiple reasons:

* By hiding the data that the test relies on in a file, you are making the test much more difficult to read and understand.
* Files pollute your code repository and in the end, you might have tons of files that you might not even be sure of if they are in use or not.
* If you place these files outside your repository (e.g. AWS S3) you introduce additional dependencies to your tests, which reduce their independence.

There are multiple other ways you can mock the `DataFrame` that are much more suitable and readable for your test suite.

### Mock Files with In-Memory File Objects
Imagine that you have some code that look like this:

    ::python
    def get_df(self, file_path):
        with open(file_path) as file:
            df = pd.read_excel(file, sheet_name=0)
        return df.rename({"foo_id": "bar_id"})

How would you test that? Some developers might follow the path that I described above where they generate a real file on the file system that they pass into the `get_df()` function as the `file_path` argument. Bad idea.

A much nicer way to go about it is to generate an in-memory Excel file that you mock the `open()` method with. This could be tested in the following manner:

    ::python
    import pandas as pd
    from io import BytesIO
    from unittest.mock import patch

    def test_get_df(self):
        # Define a DF as the contents for your excel file.
        df = pd.DataFrame({"foo_id": [1, 2, 3, 4, 5]})
        # Create your in memory BytesIO file.
        output = BytesIO()
        writer = pd.ExcelWriter(output, engine="xlsxwriter")
        df.to_excel(writer, sheet_name="Sheet1", index=False)
        writer.save()
        output.seek(0)  # Contains the Excel file in memory file.

        with patch("path.to.file.open") as open_mock:
            open_mock.return_value = output
            df = get_df("file/path/file.xslx")
            open_mock.assert_called_once_with("file/path/file.xlsx")

        pd.testing.assert_frame_equal(
            df, pd.DataFrame({"bar_id": [1, 2, 3, 4, 5]}
        )

So in the case above, we are mocking the file itself and the whole `open()` call. The `file_path` argument passed into the function does not even matter since it is never actually used. 

So as we do this, what are we even testing? What are we achieving? 

* We can see the contents of the file that gets opened directly in the test. This makes it much easier for fellow developers to understand why the test is passing or failing.
* We trust that Python's `open()` function works properly. Our unit test does not need to test it. What we care about is if it ATTEMPTS to open the file path passed in, and that it modifies the `DataFrame` in an expected way.

### Mock Pandas Read Functions
The following method where we are using `patch` to mock the loading of the `DataFrame` can also be used in other cases where files might not be used. For example, we might have the following type of code:

    ::python
    def get_df():
        df = pd.read_sql("SELECT * FROM foo;", connection)
        return df.rename({"foo_id": "bar_id"})

In this case, there is no `open()` method that loads a file object, instead, it uses the built-in `read_x` functions that exist within the Pandas library to read in the data from an external source, in this case, an SQL database.

Once again, in the context of writing unit tests, we do not care about testing the underlying SQL connection to the database. We trust that the `read_sql` function works provided to us by the `pandas` library. We also trust that the `connection` object works as expected, and even if it is something written by ourselves in-house, there should be other tests that would test the database python module used.

So what do we want to test?

1. Does the function attempt to query a database with the expected SQL query?
2. Does the function rename the columns?
3. Does the function return a dataframe?

We can achieve this with the following test:

    ::python
    from unittest.mock import patch, Mock

    @patch("path.to.file.pandas.read_sql")
    def test_get_df(read_sql_mock: Mock):
        read_sql_mock.return_value = pd.DataFrame({"foo_id": [1, 2, 3]})
        results = get_df()
        read_sql_mock.assert_called_once()
        
        pd.testing.assert_frame_equal(results, pd.DataFrame({"bar_id": [1, 2, 3]})

In this case, we use the `patch` as a decorator instead of as a context manager. When we use it as a decorator it automatically creates a mock that gets passed into the test function as an argument. 

As you can see from the test, by mocking the `read_sql` function we are able to achieve the following:

- Remove any dependency of an SQL database from our test.
- We make our test more readable since we can see inside the test what the dataframe returned from the `read_sql` function will be.
- Our test becomes an "isolated unit of code" that we test. We do not care about the other functions that the function is calling in nested ways, we only test the functionality that is limited to the `get_df` function.