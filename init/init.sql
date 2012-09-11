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

-- seed appStatus
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Available', 'icons/fugue/tick-circle.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Service disruption', 'icons/fugue/exclamation.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Service outage', 'icons/fugue/cross-circle.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Scheduled maintenance', 'icons/fugue/traffic-cone.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Emergency maintenance', 'icons/fugue/flag.png' );
INSERT INTO appStatus( appStatusDescription, appStatusImage ) VALUES( 'Engineer dispatched', 'icons/fugue/wrench.png' );

-- seed app
INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Clinician Desktop', 'MMOTS Workhorse', 1 );
INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Request Tracker', 'Technical Services Support Ticketing System', 1 );
INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Secure Office Connection (VPN)', 'IPSec VPN Tunnel', 1 );

-- service
CREATE TABLE serviceStatus (
	serviceStatusID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	serviceStatusDescription TEXT
);

CREATE TABLE service (
	serviceID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	serviceName TEXT,
	serviceDescription TEXT,
	serviceStatusID INTEGER NOT NULL REFERENCES serviceStatus( serviceStatusID ),
	statusUpdateTimestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- seed serviceStatus
INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'UP' );
-- I think we need something akin to 'REDUNDACY LOST' to indicate the potential for disruption to an upstream app
--  when a given service has n+1 hosts that provide that service (i.e. DNS)
INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'REDUNDANCY LOST' );
INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'DOWN' );

-- seed status
INSERT INTO service( serviceName, serviceDescription, serviceStatusID ) VALUES( 'DNS', 'Domain Name Service', 3 );
INSERT INTO service( serviceName, serviceDescription, serviceStatusID ) VALUES( 'Web Servers', 'Backend Web Servers', 2 );
INSERT INTO service( serviceName, serviceDescription, serviceStatusID ) VALUES( 'Web Load Balancers', 'Web Load Balancers', 1 );

-- host
CREATE TABLE hostStatus (
	hostStatusID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	hostStatusDescription TEXT
);

CREATE TABLE host (
	hostID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	hostName TEXT,
	hostDescription TEXT,
	hostStatusID INTEGER NOT NULL REFERENCES hostStatus( hostStatusID ),
	statusUpdateTimestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- seed hostStatus
INSERT INTO hostStatus( hostStatusDescription ) VALUES( 'UP' );
INSERT INTO hostStatus( hostStatusDescription ) VALUES( 'DOWN' );

-- seed host
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns1', 'DNS Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns2', 'DNS Server', 2 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns3', 'DNS Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www1', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www2', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www3', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'lb1', 'Web Load Balancer', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'lb2', 'Web Load Balancer', 1 );

-- this is where we start to build the "smarts" or glue of this system
-- host-to-service dependencies
-- define the link between the hosts and the services that depend on them
CREATE TABLE host2service (
	genericID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	hostID INTEGER NOT NULL REFERENCES host( hostID ),
	serviceID INTEGER NOT NULL REFERENCES service( serviceID )
);

-- seed host2service
---- DNS hosts to DNS service
INSERT INTO host2service( hostID, serviceID) VALUES( 1, 1);
INSERT INTO host2service( hostID, serviceID) VALUES( 2, 1);
INSERT INTO host2service( hostID, serviceID) VALUES( 3, 1);
---- web hosts to 'Web Servers' service
INSERT INTO host2service( hostID, serviceID) VALUES( 4, 2);
INSERT INTO host2service( hostID, serviceID) VALUES( 5, 2);
INSERT INTO host2service( hostID, serviceID) VALUES( 6, 2);

-- service-to-app dependencies
-- define the link between the services and the apps that depend on them
CREATE TABLE service2app (
	genericID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	serviceID INTEGER NOT NULL REFERENCES service( serviceID ),
	appID INTEGER NOT NULL REFERENCES app( appID )
);

-- seed service2app
---- DNS is required by the Clinician Desktop app
INSERT INTO service2app( serviceID, appID ) VALUES( 1, 1 );
---- The 'Web Servers' service is required by the Clinician Desktop app
INSERT INTO service2app( serviceID, appID ) VALUES( 2, 1 );
---- DNS is required by the Request Tracker app
INSERT INTO service2app( serviceID, appID ) VALUES( 1, 2 );
---- The 'Web Servers' service is required by the Request Tracker app
INSERT INTO service2app( serviceID, appID ) VALUES( 2, 2 );

-- define the link between service status and app status; generic rules
CREATE TABLE serviceStatus2appStatus (
	genericID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	serviceStatusID INTEGER NOT NULL REFERENCES serviceStatus( serviceStatusID ),
	appStatusID INTEGER NOT NULL REFERENCES appStatus( appStatusID )
);

-- seed serviceStatus2appStatus
---- service status = UP, app status = Available
INSERT INTO serviceStatus2appStatus( serviceStatusID, appStatusID ) VALUES( 1, 1 );
---- service status = REDUNDANCY LOST, app status = Service disruption
INSERT INTO serviceStatus2appStatus( serviceStatusID, appStatusID ) VALUES( 2, 2 );
---- service status = DOWN, app status = Service outage
INSERT INTO serviceStatus2appStatus( serviceStatusID, appStatusID ) VALUES( 3, 3 );
