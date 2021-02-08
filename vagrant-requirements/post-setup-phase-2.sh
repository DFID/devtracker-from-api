#!/bin/bash
cd /vagrant/
sudo rbenv install 2.5.3
sudo rbenv local 2.5.3
sudo gem install bundler -v '2.0.2'
bundle i