---
layout: post
title: Building a generic web crawler/spider in Python
date: 2021-04-09 00:00:00 +0000
categories: python
---

I've been doing web crawling and web scraping for years. It's funny but it was actually the interest in web crawling that introduced me to Python as a programming language and made me give up my precious PHP which was what I was coding with earlier in my career.

Python simply had much better tooling, and the language itself was more suitable for building background processes and projects that was not just websites depending on a HTTP request for execution (unlike PHP where everything revolve around building something that serves web requests).

My first web crawler was crawling a single massive website of product listings, and I was parsing
prices, product names, addresses, contact information and more by hardcoding what table cell, what class name, header and so on to read the data from.

This worked extremely well, for about a week. Pretty soon the source website did updates to their product pages and suddenly my parsing broke. I updated my parser and then two weeks later something else broke which required me to manually fix it. It was a never ending cat and mouse game where they were updating their website, and I was updating my crawler to match their changes...

I recently I launched a [real estate portal called Homest](https://homest.co.uk/) which is not only crawling a single source, but hundreds of sources. This is done with a single generic crawler that can crawl any of these sites without having to have detailed knowledge of the actual HTML structure that is making up these sources.

How did I do this?


## Architecture of my web crawler application

![Web crawler architecture diagram](/assets/architecture-diagram.png "Web crawler architecture")
