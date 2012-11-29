#!/usr/bin/python

# parse init.yaml and build the appropriate SQL statements to be executed so that we can seed our database with defined services, apps, and their dependencices
#
# TODO
# 1. build some static tables so that we can insert user-specified data into them
# 2. build query statements that will be required to properly seed tables using user-specified data
# 3. add exception handling EVERYWHERE
# 4. find a more robust solution to allow users to perform a test run and see what the _real_ SQL statements would look like; create the database in memory (:memory:)

import yaml, sqlite3
import pprint	# convenient for dumping data structures for debugging
import argparse
import random	# we need to address a chicken/egg scenario

# global vars
database = 'sqlite/concierge.db'
parser = argparse.ArgumentParser(description="Parse a YAML file to initialize the SQLite database that Concierge will use to store status and event information")
parser.add_argument( "-d", "--database", dest="database", help="define the location and name of the database (DEFAULT: ROOT/sqlite/concierge.db)" )
parser.add_argument( "-f", "--yaml-file", dest="yaml_file", help="define the location of the YAML file to be parsed (DEFAULT: ROOT/init/init.yaml" )
parser.add_argument( "-t", "--test-run", dest="test_run", help="DO NOT initialize the database. Simply dump the SQL statements to STDOUT", action="store_true", default=False )
args = parser.parse_args()

def queryGeneric(sql, parameters=()):
 if args.test_run:
  print sql
  return

 # NOTE: for efficiency, I may want to bundle multiple SQL statements up and call executescript()
 print sql
 print parameters
 cursor.execute( sql, parameters )
 connection.commit()

def createTables():
 sql = """
-- app
CREATE TABLE appStatus (
        appStatusID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        appStatusDescription TEXT,
        appStatusImage TEXT
);

CREATE TABLE app (
        appID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        appName TEXT,
        appDescription TEXT,
        appStatusID INTEGER NOT NULL REFERENCES appStatus( appStatusID ),
        statusUpdateTimestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE appEvents (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        appID INTEGER NOT NULL REFERENCES app( appID ),
        appStatusID INTEGER NOT NULL REFERENCES appStatus( appStatusID ),
        message TEXT,
        datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- service
CREATE TABLE serviceStatus (
        serviceStatusID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        serviceStatusDescription TEXT,
        serviceStatusImage TEXT
);

CREATE TABLE service (
        serviceID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        serviceName TEXT,
        serviceDescription TEXT,
        serviceStatusID INTEGER NOT NULL REFERENCES serviceStatus( serviceStatusID ),
        statusUpdateTimestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE serviceEvents (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        serviceID INTEGER NOT NULL REFERENCES service( serviceID ),
        serviceStatusID INTEGER NOT NULL REFERENCES serviceStatus( serviceStatusID ),
        message TEXT,
        datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- service-to-app dependencies
-- define the link between the services and the apps that depend on them
CREATE TABLE service2app (
        genericID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        serviceID INTEGER NOT NULL REFERENCES service( serviceID ),
        appID INTEGER NOT NULL REFERENCES app( appID )
);
"""
 if args.test_run:
  print sql
  return

 cursor.executescript( sql )

def seedTables():
 sql =  """
-- seed appStatus
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Available', 'icons/fugue/tick-circle.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Service disruption', 'icons/fugue/exclamation.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Service outage', 'icons/fugue/cross-circle.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Scheduled maintenance', 'icons/fugue/traffic-cone.png' );
-- seed serviceStatus
INSERT INTO serviceStatus( serviceStatusDescription, serviceStatusImage ) VALUES( 'Available', 'icons/fugue/tick-circle.png'  );
-- I think we need something akin to 'REDUNDACY LOST' to indicate the potential for disruption to an upstream app
--  when a given service has n+1 hosts that provide that service (i.e. DNS)
INSERT INTO serviceStatus( serviceStatusDescription, serviceStatusImage ) VALUES( 'Service disruption', 'icons/fugue/exclamation.png' );
INSERT INTO serviceStatus( serviceStatusDescription, serviceStatusImage ) VALUES( 'Service outage', 'icons/fugue/cross-circle.png' );
"""

 if args.test_run:
  print sql
  return

 cursor.executescript( sql )

def queryStatusID( keyType ):
 # query the IDs for app and service statuses to be used later by parseInitData()
 # keyType == 'apps' || keyType == 'services'
 # NOTE: assumes the user leaves the default statuses as-is
 if keyType == 'apps':
  sql = """
SELECT appStatusID from appStatus WHERE appStatusDescription = 'Available'
  """
 if keyType == 'services':
  sql = """
SELECT serviceStatusID from serviceStatus WHERE serviceStatusDescription = 'Available'
  """

 if args.test_run:
  rand = random.randint(1,10)	# chicken, meet egg; if we're test running, the app and service tables won't exist to query
  return rand
 else:
  cursor.execute( sql )
  row = cursor.fetchone()	# only expecting one result...
  return row[0]

def queryResourceID( keyType, resourceName ):
 if keyType == 'apps':
  sql = """
SELECT appID from app WHERE appName = ?
  """
 if keyType == 'services':
  sql = """
SELECT serviceID from service WHERE serviceName = ?
  """
 if args.test_run:
  rand = random.randint(1,10)	# chicken, meet egg; if we're test running, the app and service tables won't exist to query
  return rand
 else:
  cursor.execute( sql, (resourceName,) )
  row = cursor.fetchone()	# only expecting one result...
  return row[0]

def parseInitData( data, keyType ):
 # NOTE: order is important here; I'll need to test for race conditions where an app record is missing in the database when it's needed to insert into service2app
 # if need be, control the order of creation in the 'for keyType, data in initData.items():' loop below
 if keyType == 'services':
  for service in data:	# value is a list of hashes
   for serviceKey, serviceInfo in service.items():
    if args.test_run:
     print "\n-- " + serviceInfo['name']

    statusID = str( queryStatusID( keyType ) )
    sql =  "INSERT INTO service( serviceName, serviceDescription, serviceStatusID ) VALUES( ?, ?, ? );"
    queryGeneric( sql, (serviceInfo['name'], serviceInfo['description'], statusID) )
 elif keyType == 'apps':
  for app in data:	# value is a list of hashes
   if args.test_run:
    print "\n-- " + app['name']

   statusID = str( queryStatusID( keyType ) )
   sql =  "INSERT INTO app( appName, appDescription, appStatusID ) VALUES( ?, ?, ?);"
   queryGeneric( sql, (app['name'], app['description'], statusID) )

   # query the app table to find the newly created appID;
   appID = str(queryResourceID( keyType, app['name'] ))

   if args.test_run:
    print "---- app dependencies"

   if isinstance(app['dependencies'], dict):	# single dependency
    #use app['dependencies']['name'] to perform a lookup of the service ID for the insert below; also lookup the ID for the appropriate app via app['name']
    serviceID = str(queryResourceID( 'services', app['dependencies']['name'] ))
    sql =  "INSERT INTO service2app( serviceID, appID ) VALUES( ?, ? );"
    queryGeneric( sql, (serviceID, appID) )
   elif isinstance(app['dependencies'], list):	# multiple dependencies
    #use dep['name'] to perform a lookup of the service ID for the insert below; also lookup the ID for the appropriate app via app['name']
    for dep in app['dependencies']:
     serviceID = str(queryResourceID( 'services', dep['name'] ))
     sql =  "INSERT INTO service2app( serviceID, appID ) VALUES( ?, ? );"
     queryGeneric( sql, (serviceID, appID) )

# main

if args.database:
 connection = sqlite3.connect( args.database )	# global connection
else:
 connection = sqlite3.connect( database )	# global connection

cursor = connection.cursor()
createTables()
seedTables()

if args.yaml_file:
 yamlFile = open( args.yaml_file )	# check for failure!!
else:
 yamlFile = open( 'init/init.yaml' )

initData = yaml.load( yamlFile )
yamlFile.close()

for keyType, data in initData.items():
 if args.test_run:
  print "\n--[" + keyType + "]"
 parseInitData(data, keyType)
