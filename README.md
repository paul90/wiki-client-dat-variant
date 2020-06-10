# wiki-client (dat variant)

__*this is a work in progress*__

A variant of the Federated Wiki client-side javascript for exploring using beaker browser, and Hyperdrive based federated wiki sites.

This client is currently __not__ in step with the server based client, currently base on the May 2019 build (v0.16.0).

## Creating a New Wiki:

### Plain and Simple

You will need a recent version of Beaker Browser, *1.0 beta 1 or later*.

In Beaker Browser open the Federated Wiki Client drive, [hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6](hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6). Click on the "Creating a New Wiki" link, fill in the form, and click on "Create Wiki" button. This will create your new wiki, and open it in new browser tab.

From there you can get started creating content and sharing it with the world.

~~To share with the wider *http(s)* federation you will want to mirror your wiki site to https using remote peer like [hashbase](https://hashbase.io), or [homebase](https://github.com/beakerbrowser/homebase).~~

For more information on the Hyperdrive Protocol, visit [their website](https://hypercore-protocol.org/).

We have a chat group on Matrix, [#fedwiki:matrix.org](https://matrix.to/#/#fedwiki:matrix.org), and meet-up for a video chat on Wednesdays at 10am Pacific Time (PST/PDT) *location gets announced in chat*.

<!--
~~For those exploring this variant of wiki I have created  [dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites](dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites). To have your wiki added share it via chat.~~
-->
---

The hyperdrive version of the Federated Wiki has been split into two parts: wiki storage, client (which includes the core plugins).

~~Each wiki has its own storage hyperdrive. It has an `index.html` that loads the wiki client. There is an *empty* wiki site hyperdrive that is used in the wiki creation process as a template [dat://federated-wiki-empty-wiki.hashbase.io](dat://federated-wiki-empty-wiki.hashbase.io).~~

This [git repository](https://github.com/paul90/wiki-client-dat-variant) contains the client logic needed to display the wiki, the client subdirectory is used to create the *wiki client* drive [hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6](hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6).
