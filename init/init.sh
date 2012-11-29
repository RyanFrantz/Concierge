#!/bin/bash

# TODO:
# 1. account for the fact that a user may decide to change defaults
# 2. set the appropriate permissions for Apache to own/read the .db file

# create a home for our db
mkdir -p /root/concierge/sqlite
# remove a pre-existing db
#rm -f /root/concierge/sqlite/appStatus.db
rm -f /root/concierge/sqlite/concierge.db
# seed our db
/usr/bin/python /root/concierge/test/parseYaml.py
