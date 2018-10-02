# wiki-client (dat variant)

__*this is a work in progress*__

A variant of the Federated Wiki client-side javascript for exploring using beaker browser, and dat based federated wiki sites.

This code is based on a fork of the wiki client taken in May 2018.

## Creating a New Wiki:

### Plain and Simple

You will need a recent version of Beaker Browser, *0.8.0 prerelease 9 or later*.

In Beaker Browser open the Federated Wiki Client dat, [dat://federated-wiki-client.hashbase.io](dat://federated-wiki-client.hashbase.io). Click on the "Creating a New Wiki" link, fill in the form, and click on "Create Wiki" button. This will create your new wiki, and open it in new browser tab.

From there you can get started creating content and sharing it with the world.

To share with the wider *http(s)* federation you will want to mirror your wiki site to https using remote peer like [hashbase](https://hashbase.io), or [homebase](https://github.com/beakerbrowser/homebase).

For more information on the dat protocol, visit [their website](https://datproject.org/).

We have a chat group on Matrix, [#fedwiki:matrix.org](https://matrix.to/#/#fedwiki:matrix.org), and meet-up for a video chat on Wednesdays at 10am Pacific Time (PST/PDT) *location gets announced in chat*.

For those exploring this variant of wiki I have created  [dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites](dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites). To have your wiki added share it via chat.

---

The dat version of the Federated Wiki has been split into three parts: wiki storage, client, and plugin.

Each wiki has its own storage dat. It has an `index.html` that loads the wiki client. There is an *empty* wiki site dat that is used in the wiki creation process as a template [dat://federated-wiki-empty-wiki.hashbase.io](dat://federated-wiki-empty-wiki.hashbase.io).

This [git repository](https://github.com/paul90/wiki-client-dat-variant) contains the client logic needed to display the wiki, the client subdirectory is used to create the *wiki client* dat [dat://federated-wiki-client.hashbase.io](dat://federated-wiki-client.hashbase.io).

The client will load *plugins*, from [dat://federated-wiki-plugins.hashbase.io](dat://federated-wiki-plugins.hashbase.io), which are required to handle images and other non-plain text content. This architecture allows us to update the client and plugin, without needing individual wiki to be modified.
