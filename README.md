# Ozaria

This is a new repo cloned from https://github.com/codecombat/codecombat - where you can find the original instructions. 

The name of this repo is `ozaria`, and it connects with the Ozaria back end at https://github.com/codecombat/ozaria-server. 

Rough installation instructions are as follows:

Install [MongoDB](https://www.mongodb.org/downloads#production), Node 8.15.1, npm 6.4.1, and [Git](https://desktop.github.com/). It may be useful to install [NVM](https://github.com/nvm-sh/nvm) and install Node and NPM through that. Once it's installed, you simply run `nvm install v8.15.1`, and it will install and use the correct Node and NPM versions.

1. Clone this repo locally with `git clone git@github.com:codecombat/ozaria.git`

1. `cd ozaria`

1. `npm install`

1. [`npm link`](https://medium.com/@alexishevia/the-magic-behind-npm-link-d94dcb3a81af), which will prepare this client repo for use in the server repo afterwards

1. Go one folder up with `cd ..`

1. Clone the server repo with `git clone https://github.com/codecombat/ozaria-server`

1. `cd ozaria-server`

1. `npm install`

1. `npm link ozaria`

1. `./bin/coco-mongo` and then import the [database dump](#database)

