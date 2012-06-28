#!/usr/bin/perl

use lib "/root/concierge/lib";
use DBI;
use DBD::SQLite;
use Dancer;

use Concierge;
use Concierge::Help;

# vars
my $db = '/root/concierge/sqlite/appStatus.db';
# no user/pass combo; we're using SQLite
my $user = "";
my $password = "";

# init before any requests
my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", $user, $password )
	or die "Unable to connect to SQLite database: " . DBI->errstr . "\n";
# subs

#my $sub = sub { "Hello, World!\n\nI'm the App Status Dispatch a.k.a Concierge!\n"; };
#get '/' => $sub;
get '/' => sub {
	greeting();
};

get '/help' => sub {
	getHelp();
};

# -- apps
get '/apps' => sub {
	getResource( $dbh, 'app' );
};

# order is important; the 'all' block _must_ come before "get '/apps/:appID/status'" or it's ignored
get '/apps/all/status' => sub {
	getStatus( $dbh, 'app', 'all' );
};

get '/apps/:appID/status' => sub {
	# this should return a message on failure (i.e. invalid appID)
	my $appID = param( 'appID' );
	getStatus( $dbh, 'app', $appID );
};

# -- hosts
get '/hosts' => sub {
	getResource( $dbh, 'host' );
};

get '/hosts/all/status' => sub {
	getStatus( $dbh, 'host', 'all' );
};

get '/hosts/:hostID/status' => sub {
	# this should return a message on failure (i.e. invalid hostID)
	my $hostID = param( 'hostID' );
	getStatus( $dbh, 'host', $hostID );
};

# -- services
get '/services' => sub {
	getResource( $dbh, 'service' );
};

get '/services/all/status' => sub {
	getStatus( $dbh, 'service', 'all' );
};

get '/services/:serviceID/status' => sub {
	# this should return a message on failure (i.e. invalid serviceID)
	my $serviceID = param( 'serviceID' );
	getStatus( $dbh, 'service', $serviceID );
};

dance;
    
$dbh->disconnect;
