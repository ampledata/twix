# Makefile for twix.
#
# Home:: https://github.com/ampledata/twix
# Author:: Greg Albrecht <mailto:gba@splunk.com>
# Copyright:: Copyright 2012 Splunk, Inc.
# License:: Apache License 2.0
#



VAGRANT_CMD='/opt/vagrant/bin/vagrant'


init:
	pip install -r requirements.txt --use-mirrors

build:
	tar -X .tar_exclude -zcpf twix.spl ../twix

vagrantinit:
	$(VAGRANT_CMD) init
	$(VAGRANT_CMD) box add base http://files.vagrantup.com/lucid64.box

vagrantup:
	$(VAGRANT_CMD) up

vagrant: vagrantinit vagrantup

download_splunk:
	wget -O splunk-4.3.3-128297-linux-2.6-amd64.deb 'http://www.splunk.com/page/download_track?file=4.3.3/splunk/linux/splunk-4.3.3-128297-linux-2.6-amd64.deb&ac=&wget=true&name=wget&typed=releases'

install_splunk:
	$(VAGRANT_CMD) ssh -c 'sudo dpkg -i /vagrant/splunk-4.3.3-128297-linux-2.6-amd64.deb'
	$(VAGRANT_CMD) ssh -c 'sudo /opt/splunk/bin/splunk enable boot-start --answer-yes'

start_splunk:
	$(VAGRANT_CMD) ssh -c 'sudo /opt/splunk/bin/splunk start --answer-yes'

splunk: download_splunk install_splunk start_splunk set_splunk_password

lint:
	pylint -f parseable -i y -r y bin/*.py tests/*.py | tee pylint.log

flake8:
	flake8 --exit-zero  --max-complexity 12 bin/*.py tests/*.py | \
		awk -F\: '{printf "%s:%s: [E]%s\n", $$1, $$2, $$3}' | tee flake8.log

pep8: flake8

clonedigger:
	clonedigger --cpd-output .

nosetests:
	nosetests

test: init lint flake8 clonedigger nosetests

install_app:
	$(VAGRANT_CMD) ssh -c 'sudo /opt/splunk/bin/splunk install app /vagrant/twix.spl -update true -auth admin:ampledata'
	$(VAGRANT_CMD) ssh -c 'sudo /opt/splunk/bin/splunk restart'

upgrade: install

add_input:
	$(VAGRANT_CMD) ssh -c 'sudo /opt/splunk/bin/splunk add monitor /var/log -auth admin:ampledata'

generate_paste:
	$(VAGRANT_CMD) ssh -c 'logger -t generated paste'
	$(VAGRANT_CMD) ssh -c "sudo /opt/splunk/bin/splunk search 'generated paste | head 1 | campfire' -auth admin:ampledata"

generate_alert:
	$(VAGRANT_CMD) ssh -c 'logger -t generated alert'

delete_saved_search:
	curl -k -u admin:ampledata --request DELETE https://localhost:4189/servicesNS/admin/search/saved/searches/twix_saved_search

create_saved_search:
	curl -k -u admin:ampledata https://localhost:4189/servicesNS/admin/search/saved/searches -d name=twix_saved_search \
		--data-urlencode search='generated alert' -d action.script=1 -d action.script.filename=campfire.py \
		-d action.script.track_alert=1 -d actions=script -d alert.track=1 -d cron_schedule='*/5 * * * *' -d disabled=0 -d dispatch.earliest_time=-5m@m \
		-d dispatch.latest_time=now -d run_on_startup=1 -d is_scheduled=1 -d alert_type='number of events' -d alert_comparator='greater than' \
		-d alert_threshold=0

test_search:
	true

splunk_errors:
	$(VAGRANT_CMD) ssh -c "sudo /opt/splunk/bin/splunk search 'index=_internal \" error \" NOT debug source=*splunkd.log*' -auth admin:ampledata"

set_splunk_password:
	$(VAGRANT_CMD) ssh -c "sudo /opt/splunk/bin/splunk edit user admin -password ampledata -auth admin:changeme"

setup_app:
	curl -k -u admin:ampledata https://localhost:4189/servicesNS/nobody/twix/apps/local/twix/setup -d /campfire/api/api/subdomain=$(CAMPFIRE_SUBDOMAIN) -d /campfire/api/api/room_name=$(CAMPFIRE_ROOM_NAME) -d /campfire/api/api/auth_token=$(CAMPFIRE_AUTH_TOKEN)

reinit: build install_app setup_app generate_alert delete_saved_search create_saved_search

cli_lint:
	pylint -f colorized -i y -r n bin/*.py tests/*.py

cli_flake8:
	flake8 --max-complexity 12 bin/*.py tests/*.py

clean:
	rm -rf *.egg* build dist *.pyc *.pyo cover doctest_pypi.cfg nosetests.xml \
		pylint.log *.egg output.xml flake8.log output.xml */*.pyc .coverage
