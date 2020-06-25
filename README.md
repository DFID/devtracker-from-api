# Development Tracker using the OIPA public API

[![Coverage Status](https://coveralls.io/repos/DFID/devtracker-from-api/badge.svg?branch=master&service=github)](https://coveralls.io/github/DFID/devtracker-from-api?branch=master)

This repository is to support the redevelopment of Development Tracker using the [OIPA open public API](https://www.oipa.nl/home) instead of the more complex data back-end used in the [orginal DevTracker](https://github.com/dfid/aid-platform-beta). 

## About DevTracker
The Development Tracker (often just called DevTracker) is a public web platform that allows users to access information on the UK's contribution to the global effort to eliminate extreme poverty. 

Users are members of the public, journalists, researchers, civil society organisations, politicians, officials in the UK, in other donor countries and in countries where the UK supplies official development assistance.

DevTracker uses open data published by the UK Government and its partners in the [International Aid Transparency Initiative](http://iatistandard.org) (IATI) format. The IATI format is an XML-based international data standard and therefore requires some manipulation to make it readable by non-technical people. That is what DevTracker attempts to do.

## OIPA
The open public API being used in the [OIPA API](https://www.oipa.nl/home) built by [Zimmerman & Zimmerman] (https://www.zimmermanzimmerman.nl/).

## Get started
The site is being developed using a Sinatra web framework and Ruby. To get started, go to the [Wiki](https://github.com/DFID/devtracker-from-api/wiki). We will be adding new guidance and features to the wiki as we go along.

## Load DevTracker Using Vagrant
If you do not want to setup the whole environment using the manual process and would rather prefer a quick vagrant setup, please follow the below steps

```
vagrant up
vagrant ssh
# Give execute permission to the following scripts
chmod +x /vagrant/vagrant-requirements/post-setup-phase-1.sh
chmod +x /vagrant/vagrant-requirements/post-setup-phase-2.sh
# Run the first script
/vagrant/vagrant-requirements/post-setup-phase-1.sh
# Exit from the console as the running scripts need a reloaded login of the current user
exit
# Login again using vagrant ssh
vagrant ssh
# Run the following script
/vagrant/vagrant-requirements/post-setup-phase-2.sh
# Once everything's complete, edit devtracker.rb to a publicly accessible OIPA endpoint. Just follow [this link](https://github.com/DFID/devtracker-from-api/wiki#do-this-first-on-a-dev-machine) to make the change.
# Run the following command
ruby devtracker.rb -o 0.0.0.0 -p 4567

# Now from the host machine web browser, go to http://localhost:8080 and you will have a running devtracker
```