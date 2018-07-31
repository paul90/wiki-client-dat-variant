# wiki-client (dat variant)

__*this is a work in progress*__

A variant of the Federated Wiki client-side javascript for exploring using beaker browser, and dat based federated wiki sites.

This code is based on a fork of the wiki client taken in May 2018.

# Forking the Wiki using Dat:

## Plain and Simple

To create your own wiki to share with others on the Decentralized Web, simply fork your own copy of the wiki,
which is located at **dat://dfd9ad6488bad49a06a36904468d40fc8ac4a1ea14cedd78c23a7bed753ca9f7**.
The easiest way to view and fork dat:// files is by using [the Beaker Browser](https://beakerbrowser.com/).
Once you have your own fork, you will get your own dat url. Opening this url in Beaker will allow you to edit your wiki copy!
From there you can get started creating content and sharing it with the world.
For more information on the dat protocol, visit [their website](https://datproject.org/).

## The Full Story

The dat version of the Federated Wiki has been split into three parts: storage, client, and plugin. 
This repository contains the client logic.
The "storage" repository holds an individual wiki instance's files,
and this is the part that users will fork to create their own wiki instances (link above).
This repository contains the client logic needed to display the wiki.
The storage repository links to this client library, which is currently hosted at **dat://b9f4332d8a3ff9acbfdfe16d597c25af8f4143bd333e6c49496ef0e39626f2e2**.
Once the client is loaded, it loads a number of plugins from **dat://763c9f8d5769fb8d838abb4ba07390a0a80d2fdfb4508149e09e2f34364d2421**,
which are required to handle images and other non-plain text content. This architecture allows us to update the client and plugin
libraries without forcing users to constantly keep their "storage" dats up-to-date.
However you are free to fork the client & plugin libraries, and configure your storage repository to point to your new copies.
