---
layout: post
title: 7 things to know as a Senior Software Engineer
date: 2019-01-17 00:00:00 +0000
categories: docker
permalink: /@marcus/7-things-to-know-as-a-senior-software-engineer/
---

Are you looking for how you can take the next step in your career and move on to become a senior software engineer? This year I celebrate my 10th year of professional software engineering experience and during this long journey where I moved from being a junior web developer to becoming a senior software engineer I learned a lot of valuable lessons that I feel made me mature enough to be considered a senior member of any team.

## Writing good code doesn't make you senior
By the name of the title "Senior Software Engineer" or "Senior Developer", its easy to come to the conclusion that the part that makes you senior is the quality of the code you're writing. Obviously its true that as a senior engineer you're expected to write high quality code, but that expectation is true for any type of engineer.

No matter if you're senior or not, you're still a professional. You're still expected to produce high quality work that you would feel proud over. Therefor its simply not enough to just be "good at writing code" to become a senior member of a team, the fact that you write good code just means that you're not lazy and that you have pride in your work.

The parts that separate a senior engineer from the rest of the team isn't necessarily the code itself, instead it's more things around the code.

I've carried a lot of hats throughout my career where I've learned a lot of valuable lessons:

- As a Startup Founder I learned to understand the business perspective and how important that the work that is being done creates value for the company.
- While working in an Agency I learned how to communicate with clients and understand other people's needs, perspective and technical limitations. Things that might be obvious with technical people in a team might not be very obvious after hand-off.
- As a consultant that work temporarily on projects I learned to consider how a project will continue its life after I'd moved on to the next project, and how other developers would need to pickup where I'd left off.

These things combined with the ability to lead other team members, being able to predict the future of a project and having a broader perspective are the things that pushed me forward in my career and moved me into the position of being considered a senior member of a team.

## Reduce future maintenance
Just a few weeks ago I was working on a project of a distributed system with multiple moving pieces that were all communicating with each other through Message Queues. The team had build their own worker's that was processing the messages asynchronously with code that was running on multiple threads. It all seemed fancy and I'm sure that the programmer who wrote the code felt proud of his work.

The problem was that during the last few months, in the peak of the year for the company's revenue they had been experiencing a lot of issues with this worker that was processing messages from the Message Queue.

The problems included things such as:

- Threading bugs and race conditions.
- Lack of logging and difficulties to debug.
- Random crashes due to exceptions being raised but ignored because of try-catch blocks that was silencing the errors. 

On top of this, the code itself had been written in a hurry and even though it was technically pretty advanced, it was also quite complex and difficult to get into as a new developer. There was no simple interface to the classes that made things easy to use, instead you had to have a pretty good understanding of the whole code base to truly understand how to use it.

I was immediately comparing this code to [Celery](http://www.celeryproject.org/). In fact many of the things that had been written was reminding me of how Celery treats things and it looked like the developer who created it had been strongly influenced by Celery. So why not just use the open source project with 700 contributers and 11000 commits?

The team claimed that Celery had "too much overhead" and it contained multiple features they didn't need, so they had decided to create their own solution instead. But this also means that they would have to maintain and fix bugs within their own solution forever.

It all came down to a final thing in the end. Does this code help us increase the revenue of the company or not? If not, why would we spend resources in maintaining something that already exist out there? The decision was made to scrap the custom code and move to a solution that would be maintained for us -- for free.

## Don't write code because it's fun
The previous story about Celery can teach us more than just one lesson. It is also a perfect example of one of the most common mistakes that any engineer does, falling for the idea of writing something just because its fun or cool.

How many times haven't we met new developers who want to create their own CMS, their own [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping), or perhaps their own deployment tools?

Obviously we should be happy and proud of our fellow open source contributers who create new tools for us to use and move software engineering forward. But why invent the wheel all over again? I'm telling you, its almost never a good idea. Especially if you can't commit to maintaining it.

Find existing tools that are maintained by a community of developers. It doesn't make you a "worse" engineer just because you don't write all of the code yourself. Reusing existing tools and code is an example of a great programmer, not a bad one.

## Write code the way you want others to
I never thought that the Bible would teach us lessons applicable to programming and software engineer, but this quote couldn't be more applicable.

> Do to others as you would have them do to you.
> Luke 6:31

A year ago or so, I was working on a project that unfortunately had decided to go down the path of creating their own web framework, it was attempting to follow the Model-View-Controller pattern and when I opened my first controller I was met by a class with a single function called `public function execute()` which was literally 8000 lines long. Ouch.

Simply put, the person who wrote that code didn't ever expect to have to look at it again, and he definitely didn't care for whoever would take over the maintenance of his code after he'd moved on to his next project. Sounds like a team player? I think not.

Think about this when you write code yourself. Would you want to be given the responsibility to maintain the code that you're producing if it was written by someone else?

Compare this with code that has:

- Docstrings.
- Unit Tests.
- Expressive naming of methods or classes.
- Small, digestible chunks of code.

Don't make judgment calls that leads to low quality code just because you don't need it personally. Instead think about the next person in line. Imagine that the code you're writing will probably live for many years to come, but you might just be involved for a few months. Someone will need to at least read through your code at one point or another, and its your responsibility as a professional engineer to make it easy for them.

## Predict the future direction of the application
In today's world of agile development, an application is hardly ever just "done". Product owners always want to gather feedback from users and iterate on features. You might need to completely replace some functionality with some library, or what might have started as a traditional server side rendered application might have turned into just a REST API with a separate frontend application.

You never know what direction the development might turn to and it's important to try to keep things loosely coupled where it can, so that your application can be flexible for the future. This is a great sign of a senior developer. 

As a senior developer you will be able to predict these kind of things based on your experience. You might know that there's a pretty slim change that you will have to change database so its fine if its tightly coupled with your code, but on the other hand it's a pretty high chance that you will replace the frontend libraries or frameworks within just a few years, and you will have the foresight to prepare for that by making sure that the frontend might be easily replaceable and decoupled from the business logic of your application.

## Teach others and become a leader
Being the only developer of a team and calling yourself "senior" does not mean much. The title "Senior" implies that there are other members of your team who isn't senior and who rely on you to some extent with your additional knowledge and skills.

If you want to become a senior engineer, you should get used to the idea of helping others with growing in their own careers by teaching them the lessons you've learned from your own experiences.

In today's professional environment you will be expected to contribute to your team in many different ways. Perhaps you will sit in on meetings and advice on the architecture of the application, or maybe you will be responsible for reviewing all the code that gets pushed to the repository. Learning how to help people efficiently will be a core part of your role as a senior member of a team.

Organize team seminars, join meetups, record YouTube videos, write blog posts, answer questions on [StackOverflow](https://stackoverflow.com/) or offer yourself to review your team's code. You might have the famous "imposter" syndrome and ask yourself what's so special about yourself -- but don't worry about that, just start sharing! If you truly feel like you don't have anything to teach, then start studying!

Learn a new technology, build a demo application, study patterns or read up on the [12 Factor](https://12factor.net/). Just by doing something you're doing more than most people, and you will definitely have things to share within no-time.

## Ask yourself, does this scale?
Scaling is the act of making something work well as it grows larger and in the context of programming scaling could mean many different things. 

- Does it scale from a performance perspective?
- Does it scale in a team perspective?
- Does it scale from a user perspective?

### Scaling performance of code
The most obvious type of scaling is making sure that your code runs well on a larger dataset. For example, does your query run fast no matter if the table has 100 rows or 10'000'000 rows?

The feature you might be working on right now might be on a quite small scale. For example, you might create a search function that will search for content within articles. This might work fine when you have 100 articles, but will it when you have thousands?

Similarly as the previous section when you're expected to be able to predict the future direction of the application, you should also be able to predict the future usage of the feature you're building and you're expected to take this into account when you're writing your code. Some things need to scale, some things doesn't. Its your job to figure out what does.

### Scaling code for your team
In the beginning of a project you might be the only programmer on it, or you might work on a very small team, but as your application gains more traction you will receive more resources to your project and your team might start to scale.

Suddenly you went from being the person responsible for the whole project, to having to split the responsibilities with new people that you might not know very well. How do you make sure that your code and project does not drop in quality when this happens?

- Use Code Reviews from the first day that you're not alone anymore.
- Always write code with the expectation that someone else will maintain it in the future. Remember to use constants inside of hard coded numbers, always add docstrings even if it's obvious to you what a method does, and make sure that your code got tests so that its easy for new developers to do refactoring while still staying confident that things are working.
- Use linting tools to make sure that everyone follow the same style and patterns.
- Use a CI/CD Pipeline from day 1 even when you're working alone, to make sure that broken code never goes into your release branch.

### Scaling features for the user
A while ago I was working on a project that used machine learning to predict the optimal prices for a company that had retail stores all over the world. My responsibility of the project was to build the dashboard that allowed the staff and employees of the company to upload data that the machine learning algorithm would use to predict the prices.

In the beginning we were only suppose to work with a small subset of the retail stores that belonged to the company, because of this tasks such as supporting the users weren't an issue at all, but what about when we would start scaling our application to the rest of the company and it would go out to thousands of stores? Would we have the time to support and help out every single staff member that required our help?

This type of scaling is not necessarily related to performance. It's about use case. What might be a nice work flow in the beginning might become disastrous when you scale. As a senior engineer, even if its not your job to design the actual user interface or the features themselves, you're still expected to think about these things and be part of the discussion with the product owners, and look ahead for future problems. 

You're job is to create a system that can scale both on a performance level, but also on a user level. You get paid the big money because they expect you to be able to create work that can handle large amount of users, from multiple perspectives.
