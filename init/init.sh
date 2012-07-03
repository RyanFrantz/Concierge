#!/bin/bash

# TODO: lots...

# create a home for our db
mkdir -p /root/concierge/sqlite
# remove a pre-existing db
rm -f /root/concierge/sqlite/appStatus.db
# seed our db
sqlite3 -init /root/concierge/init/init.sql /root/concierge/sqlite/appStatus.db
