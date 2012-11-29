#!/usr/bin/perl

use lib "/root/concierge/lib";
use DBI;
use DBD::SQLite;
use Dancer;

use Concierge;
use Concierge::Help;

# vars
my $db = '/root/concierge/sqlite/concierge.db';
# no user/pass combo; we're using SQLite
my $user = "";
my $password = "";

# init before any requests
my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", $user, $password )
	or die "Unable to connect to SQLite database: " . DBI->errstr . "\n";
# subs

#get '/' => sub {
#	greeting();
#};

get '/' => sub {
	my $vars = getStatus($dbh, 'app', 'all');
	template 'app.tt', $vars;
};

get '/help' => sub {
	getHelp();
};

# -- apps
get '/apps' => sub {
	getResource( $dbh, 'app', 'all' );
};

# order is important; the 'all' block _must_ come before "get '/apps/:appID/status'" or it's ignored
get '/apps/all/status' => sub {
	my $vars = getStatus( $dbh, 'app', 'all' );
	template 'app.tt', $vars;
};

get '/apps/:appID/status' => sub {
	# this should return a message on failure (i.e. invalid appID)
	my $appID = param( 'appID' );
	my $datetime = 'all';	# get 'em all!
	my $vars = getEvents( $dbh, 'app', $appID, $datetime );
	template 'statusHistory.tt', $vars;
};

get '/apps/:appID/status/:datetime' => sub {
	# this should return a message on failure (i.e. invalid appID)
	my $appID = param( 'appID' );
	my $datetime = param( 'datetime' );
	my $vars = getEvents( $dbh, 'app', $appID, $datetime );
	template 'statusHistory.tt', $vars;
};

post '/apps/:appID/status' => sub {
	my $appID = param( 'appID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	postStatus( $dbh, 'app', $appID, $statusID );
};

post '/apps/:appID/events' => sub {
	my $appID = param( 'appID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	my $message = param( 'message' );	# passed in the POST content
	postEvent( $dbh, 'app', $appID, $statusID, $message );
};

# -- hosts
get '/hosts' => sub {
	getResource( $dbh, 'host' );
};

get '/hosts/all/status' => sub {
	getStatus( $dbh, 'host', 'all' );
};

# host dependencies
get '/hosts/:hostID/deps' => sub {
	my $hostID = param( 'hostID' );
	getDeps( $dbh, 'host', $hostID );
};

get '/hosts/:hostID/status' => sub {
	# this should return a message on failure (i.e. invalid hostID)
	my $hostID = param( 'hostID' );
	getStatus( $dbh, 'host', $hostID );
};

post '/hosts/:hostID/status' => sub {
	my $hostID = param( 'hostID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	postStatus( $dbh, 'host', $hostID, $statusID );
};

# -- services
get '/services' => sub {
	#getResource( $dbh, 'service', 'all' );
	my $vars = getStatus( $dbh, 'service', 'all' );
	template 'service.tt', $vars;
};

get '/services/all/status' => sub {
	my $vars = getStatus( $dbh, 'service', 'all' );
	template 'service.tt', $vars;
};

# service dependencies
get '/services/:serviceID/deps' => sub {
	my $serviceID = param( 'serviceID' );
	#getDeps( $dbh, 'service', $serviceID );
	processDeps( $dbh, 'service', $serviceID );
};

get '/services/:serviceID/status' => sub {
	# this should return a message on failure (i.e. invalid serviceID)
	my $serviceID = param( 'serviceID' );
	my $datetime = 'all';	# get 'em all!
	my $vars = getEvents( $dbh, 'service', $serviceID, $datetime );
	template 'statusHistory.tt', $vars;
};

post '/services/:serviceID/status' => sub {
	my $serviceID = param( 'serviceID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	postStatus( $dbh, 'service', $serviceID, $statusID );
};

post '/services/:serviceID/events' => sub {
	my $serviceID = param( 'serviceID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	my $message = param( 'message' );	# passed in the POST content
	postEvent( $dbh, 'service', $serviceID, $statusID, $message );
	processDeps( $dbh, 'service', $serviceID, $statusID, "$message See <a href=\"http://status.ryanfrantz.com/services/$serviceID/status\">http://status.ryanfrantz.com/services/$serviceID/status</a> for more information." );
};

get '/services/:serviceID/status/:datetime' => sub {
	my $serviceID = param( 'serviceID' );
	my $datetime = param( 'datetime' );
	my $vars = getEvents( $dbh, 'service', $serviceID, $datetime );
	template 'statusHistory.tt', $vars;
};

dance;
    
$dbh->disconnect;
