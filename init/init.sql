-- app
CREATE TABLE appStatus (
	appStatusID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	appStatusDescription TEXT
);

CREATE TABLE app (
	appID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	appName TEXT,
	appDescription TEXT,
	appStatusID INTEGER NOT NULL REFERENCES appStatus( appStatusID ),
	statusUpdateTimestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO appStatus( appStatusDescription ) VALUES( 'Available' );
INSERT INTO appStatus( appStatusDescription ) VALUES( 'Service disruption' );
INSERT INTO appStatus( appStatusDescription ) VALUES( 'Service outage' );

INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Clinician Desktop', 'MMOTS Workhorse', 2 );
INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Request Tracker', 'Technical Services Support Ticketing System', 1 );
INSERT INTO app( appName, appDescription, appStatusID ) VALUES( 'Secure Office Connection (VPN)', 'IPSec VPN Tunnel', 3 );

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

INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'UP' );
-- I think we need something akin to 'REDUNDACY LOST' to indicate the potential for disruption to an upstream app
--  when a given service has n+1 hosts that provide that service (i.e. DNS)
INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'DOWN' );
INSERT INTO serviceStatus( serviceStatusDescription ) VALUES( 'REDUNDANCY LOST' );

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

INSERT INTO hostStatus( hostStatusDescription ) VALUES( 'UP' );
INSERT INTO hostStatus( hostStatusDescription ) VALUES( 'DOWN' );

INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns1', 'DNS Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns2', 'DNS Server', 2 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'dns3', 'DNS Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www1', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www2', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'www3', 'Backend Web Server', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'lb1', 'Web Load Balancer', 1 );
INSERT INTO host( hostName, hostDescription, hostStatusID ) VALUES( 'lb2', 'Web Load Balancer', 1 );
