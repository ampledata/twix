# Vagrantfile for twix.
#
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Author:: Greg Albrecht <mailto:gba@splunk.com>
# Copyright:: Copyright 2012 Splunk, Inc.
# License:: BSD 3-Clause
#


Vagrant::Config.run do |config|
  config.vm.box = 'base'
  config.vm.forward_port 8000, 4180
  config.vm.forward_port 8089, 4189
end
