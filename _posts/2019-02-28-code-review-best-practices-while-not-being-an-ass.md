---
layout: post
title: Code Review Best Practices While Not Being an Ass
date: 2019-02-28 00:00:00 +0000
categories: docker
permalink: /@marcus/code-review-best-practices-while-not-being-an-ass/
---

Personally, I feel that code reviews have been one of the key tools in my toolbox that have helped me develop the most within the past few years. 

Not only has it helped me and the team that I'm working with to create a high quality, consistent and easy-to-use code base, but it has also given me great perspectives and insight into what I can do better, and how I can take the next steps into becoming a better software engineer.

If you've ever given a code review, I'm sure that you've had to face the thought of if you're coming across as an asshole, douchebag or annoying to the coworker that you're reviewing the code of. How do you give a code review that helps and improve the work of others, instead of demotivating and put other people down?

Let's talk about the lessons that I've learned across the teams that I've worked with, some who did do code reviews and some who didn't, and what benefits there are to doing them.

In my case, I'm doing a lot of Python work, and this article will talk about code reviews in the context of Python. Most of these concepts can, however, be applied to a project no matter what programming language is being used.

## 1. Create a Code Guidelines Document
One of the main things that make you worry about coming off as a negative or annoying coworker while doing code reviews is stylistic and subjective comments about code.

Do you prefer Google style Docstrings? Relative imports vs Absolute imports? Naming conventions of variables?

When you see someone naming a variable `path_to_file` and you prefer it to be named `file_path`, is it OK to comment about something like that? It's technically not "wrong" to name it `path_to_file`.

These type of questions pop up all the time when you're conducting a code review, and they are very difficult to deal with on the fly, but there is a very simple solution - create an official document of guidelines.

You don't even have to necessarily create your own from scratch, [Google has a great style guide for python](https://google.github.io/styleguide/pyguide.html) that is open source and free for anyone to take a look at. By giving the whole team a source of "truth" when it comes to certain stylistic choices, it makes it much easier to comment on, since you can always refer to the style guide instead of your own personal opinions.

For example, in the case of the Google style guide, they clarify things such as:

- How should we write docstrings?
- How should we do imports and namespacing?
- Is it OK to use global variables?
- When is it OK to do a list comprehension and when is it not?
- Is Type hinting required?

By defining these rules upfront, there is no need for a debate on these topics, instead, the code reviewer can simply call them out and refer to the official document that the whole team agreed on beforehand.

Obviously, the Google style guide does not cover every scenario and situation, and it's completely fine to use it but then add additional rules on top of it that you feel is a good fit for your project. Perhaps rules about unit tests, integration tests or if docstrings are required.

## 2. Use Automated Linting and Testing Before Code Reviews
Code Reviews are supposed to be done after testing, but before merging the code to the release branch. This means that the code should be "as close to done" as possible before the code reviewer sits down to take a look at the code.

There's nothing more annoying than to set aside half an hour of your day to help someone else with their code, and then you run into multiple problems that could have been solved by automated checks.

Make sure that you have a Continuous Integration pipeline that does things such as:

- Static analysis/linting of the code using tools such as flake8 or pylint.
- Run the full test suite of the code, both unit tests, and integration tests.

By doing this, you can avoid having to review mistakes that are already covered in PEP8 or the language's official guidelines which the linter should take care of. By making sure that the developer must first make sure that any automated testing passes, you can minimize the amount that a coworker must review and give feedback on.

### Static Analysis using Flake8
Both in my private and official projects, I'm generally using flake8 to do static analysis of my code. It's a great tool that is incredibly popular within the Python community and it has a lot of flexibility when it comes to extensions that enhance the features of the linter, and configuration that allows you to customize the linting to your own style guide and rules.

By default, it will check that you are following Python's PEP8 style rules, but on top of this, I also prefer to extend it with type checking and even docstring checks.

This can be done using the extensions:
- [flake8-mypy](https://github.com/ambv/flake8-mypy)
- [flake8-docstrings](https://github.com/PyCQA/flake8-docstrings)

flake8-mypy uses mypy which is the most popular type checker in the Python community at this time around and it works great. 

flake8-docstrings allow you to enforce usage of docstrings within your code.

A lot of people disagree with enforcing docstrings, but I enjoy this little extension, especially since you can limit its checks to only enforce docstrings on certain levels such as function/methods, classes or modules. I suggest that you have a discussion with the team to decide if this is something you want to enforce or not.

## 3. Enforce Rules You've All Agreed On
So far in this article we have covered static analysis and creating official style guides that the whole team agree on. Both of these concepts are there to make sure that there is less subjectivity in the code reviews, to make sure that you don't have to worry about not having grounds for the feedback that you give.

This means that we've already laid out the ground rules at this point, and now it is time to enforce it. This means that when you see mistakes, it is your job as a coworker to call them out.

If there is anything that is part of these official definitions of what standards your team should follow, then feel free to go straight to the point with a short comment such as:

> Change the name of the variable to follow the style guide.

> Missing type hints.

> Missing docstring.

There is no need to explain or excuse yourself, just get to the point. 

The more complicated cases are when there are some ambiguity involved. For example, let's take a look at the following example.

```python
def process(file: str):
    pass
```

Are we passing in a file object or a file path? The naming indicates that there is a file being passed in, while the type hint indicates that perhaps it's a path to a file. Which one is it?

In these cases when you're confused, and there is no "objective" rule to point at, what do you do? Well, you're confused, aren't you? That's a good enough reason to at least ask about it!

Even if the programmer that wrote the code did everything right, a code review is there to create a better experience not only for the programmer who wrote the code, but also the team member who's reading the code. Clarifying any confusion is part of the process!

## 4. Offer a Helping Hand to Struggling Team Members
Learning programming in the early 2000's with IRC and internet forums made people like myself grow some thick skin and be prepared for some hard criticism as soon as we made mistakes or asked "stupid" questions. 

That was the internet where we interacted behind anonymous pseudonyms with strangers that we never met. A code review is different, we're working and giving feedback on our coworkers, people who we share dinner with and meet on a daily basis for years. It's a good idea to attempt to be a bit "politically correct" and soften the blow from time to time.

The other day I was doing a code review that ended up with 60 comments on it. Even though I still feel like it's "correct" to point out mistakes made in code, I obviously still have an understanding about the frustration and tiredness that the engineer must feel when he opens his inbox and sees all those criticizing comments.

In this particular case, most of the issues with his code were not really his fault. He had been given the wrong information by another team member which resulted in a ton of bugs being introduced in his pull request that needed fixing.

Remember, these are our friends, coworkers, and neighbors. These are the people that we share 9 hours (in my case 13+ hours!) a day with. Be nice, be a team member.

In this case, I even apologized (even though I had nothing to do with it) that he had been given the wrong instructions, and I attempted to share the responsibility of all the misses and offered my help to solve all of the problems in the format of a pair-programming session.

If you see a coworker struggling or having a tough time, reach out to them and give them a helping hand instead of treating them as a random person on an IRC channel.

## 5. Give Compliments in the Code Review
The point of commenting on someone's code during a code review is to give them criticisment and tell them what they've done wrong and what they can improve on. This can end up being a long list of comments that can be quite demoralizing to a programmer. 

Try to remember this, and try to compliment and encourage your coworkers when they are doing a great job. The place for this is not necessarily in comments of the actual code, but most code reviewing tools give the ability to comment on the pull request itself.

After giving feedback on the code, try to leave a comment on the pull request itself that acknowledges the positives that the pull request is achieving. 

For example:

> It's so great to see so much code being removed and refactored into cleaner code! I left a few comments on things to improve, tell me if you have any questions.

This makes a huge difference in the engineer's perspective. Instead of having to start their day by going back to what they did the day before (and they thought they were finally done with!) and to fix all their mistakes, they get an acknowledgment of that their work has value and is important for the project. 

Personally, I love it when my code reviewers give these kinds of comments.

## Conclusion
I both give and receive code reviews of all my work. Both of these perspectives teach me new things of software engineering and I feel that this has been the most influential practice to me throughout the past few years. 

 This article is not only based on what I try to do when I give reviews to my coworkers, but it's also based on how I want to be treated when people review my code.

How do you feel? Do you have any suggestions of good practices that you try to follow when giving code reviews to your friends and coworkers?
