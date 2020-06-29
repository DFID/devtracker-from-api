## Run DevTracker Locally Using Vagrant

[Back to README.md](../README.md)

If you do not want to setup the whole environment using the manual process and would rather prefer a quick vagrant setup, please follow the below steps.

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
cd /vagrant
ruby devtracker.rb -o 0.0.0.0 -p 4567

# Now from the host machine web browser, go to http://localhost:8080 and you will have a running devtracker
```

### Debugging in VS Code

After successfully setting up Vagrant, run `vagrant ssh-config` in the main working directory. This will return something like this:

```
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/roryscott/Code/DFID/devtracker-from-api/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

Change the `Host` variable to `devtracker_vagrant` and adding the following entry in the `.ssh/config` file (shown when you set up a new remote connection using VS Codes 'Remote Explorer' plugin). This will allow you to run a client of VS Code from within the vagrant box.

In turn, you can install the "Ruby" extension for VS Code which allow for linting and de-bugging.

To do this, the following steps are required:

1. vagrant up within the home directory
2. connect to remote instance by going to remote explorer > ssh targets, and connecting to `devtracker_vagrant`
3. within devtracker vagrant open the `/vagrant/` folder in VS Code Explorer
4. within devtracker vagrant open a terminal and run `sudo gem install ruby-debug-ide; sudo gem install debase`
5. go to the 'Run' window and run 'Debug DevTracker`

You can now visit the dev instance by going to `localhost:8080` on your host machine, and you can enter breakpoints in the ruby code within the remote VS Code session and interactively debug.