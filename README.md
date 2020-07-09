# wiki-client (hyperdrive variant)

A variant of the Federated Wiki client-side javascript for exploring using beaker browser, and Hyperdrive based federated wiki sites.

This hyperdrive wiki client is currently level with the June 2020 build (v0.20.3) of the Node version.

## Creating a New Wiki:

You will need a recent version of Beaker Browser, *1.0 beta 1 or later*.

In Beaker Browser open the Federated Wiki Client drive, [hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6](hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6). Click on the "Creating a New Wiki" link, fill in the form, and click on "Create Wiki" button. This will create your new wiki, and open it in new browser tab.

From there you can get started creating content and sharing it with the world.

## Sharing your wiki:

The default configuration for Beaker will leave the hyperdrive daemon running in background to share your hyperdrives with others. If you are writing together with others, you may want to use the option to ["Host This Drive"](https://docs.beakerbrowser.com/beginner/hosting-hyperdrives) to help keep each others wiki available online.

There currently is not a simple option to share a hyperdrive wiki with the wider http(s) based federation, as it was with the previous version of Beaker. It is hoped that an easy way of doing this is available soon.

<hr>

For more information on the Hyperdrive Protocol, visit [their website](https://hypercore-protocol.org/).

We have a chat group on Matrix, [#fedwiki:matrix.org](https://matrix.to/#/#fedwiki:matrix.org), and meet-up for a video chat on Wednesdays at 10am Pacific Time (PST/PDT) *location gets announced in chat*.

<!--
~~For those exploring this variant of wiki I have created  [dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites](dat://paul90-dat-wiki.hashbase.io/#view/dat-wiki-sites). To have your wiki added share it via chat.~~
-->
---

The hyperdrive version of the Federated Wiki has been split into two parts: wiki storage, client (which includes the core plugins). The wiki client is mounted within each wiki's hyperdrive as a [mounted frontend](https://docs.beakerbrowser.com/developers/frontends-.ui-folder).

This [git repository](https://github.com/paul90/wiki-client-dat-variant) contains the client logic needed to display the wiki, the client subdirectory is used to create the *wiki client's* hyperdrive [hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6](hyper://cbbc6003c42ba597635ef590e326b59512c06c56d61b100aa141ed51011a29e6).
