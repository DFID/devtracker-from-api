# Development Tracker using an open public API
This repository is to support the redevelopment of Development Tracker using the [OIPA open public API](http://www.oipa.nl) instead of the more complex data back-end used in the [orginal DevTracker](https://github.com/dfid/aid-platform-beta). 

## About DevTracker
The Development Tracker (often just called DevTracker) is a public web platform that allows users to access information on the UK's contribution to the global effort to eliminate extreme poverty. 

Users are members of the public, journalists, researchers, civil society organisations, politicians, officials in the UK, in other donor countries and in countries where the UK supplies official development assistance.

DevTracker uses open data published by the UK Government and its partners in the [International Aid Transparency Initiative](http://iatistandard.org) (IATI) format. The IATI format is an XML-based international data standard and therefore requires some manipulation to make it readable by non-technical people. That is what DevTracker attempts to do.

## OIPA
The open public API being used in the [OIPA API](http://www.oipa.nl) built by Zimmerman & Zimmerman.

## Get started
The site is being developed using a Sinatra web framework and Ruby. To get started, go to the [Wiki](https://github.com/DFID/devtracker-from-api/wiki).

    $ cd site
    $ bundle
    $ ruby devtracker.rb
    ...
    $ open http://localhost:4567
