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

#get '/' => sub {
#	greeting();
#};

get '/' => sub {
	my $vars = greeting();
	template 'base.tt', $vars;
#	template 'base.tt', {
#		'name'		=>	$vars->{ 'name' },
#		'title'		=>	$vars->{ 'title' },
#		'logout_url'	=>	$vars->{ 'logout_url' },
#	};
};

get '/help' => sub {
	getHelp();
};

# -- apps
get '/apps' => sub {
	getResource( $dbh, 'app' );
};

get '/apps2' => sub {
	my $vars = getStatus($dbh, 'app', 'all');
	template 'app.tt', $vars;
};

# order is important; the 'all' block _must_ come before "get '/apps/:appID/status'" or it's ignored
get '/apps/all/status' => sub {
	getStatus( $dbh, 'app', 'all' );
};

get '/apps/:appID/status' => sub {
	# this should return a message on failure (i.e. invalid appID)
	my $appID = param( 'appID' );
	my $vars = getStatus( $dbh, 'app', $appID );
	template 'app.tt', $vars;
};

post '/apps/:appID/status' => sub {
	my $appID = param( 'appID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	postStatus( $dbh, 'app', $appID, $statusID );
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
	getResource( $dbh, 'service' );
};

get '/services/all/status' => sub {
	getStatus( $dbh, 'service', 'all' );
};

# service dependencies
get '/services/:serviceID/deps' => sub {
	my $serviceID = param( 'serviceID' );
	getDeps( $dbh, 'service', $serviceID );
};

get '/services/:serviceID/status' => sub {
	# this should return a message on failure (i.e. invalid serviceID)
	my $serviceID = param( 'serviceID' );
	getStatus( $dbh, 'service', $serviceID );
};

post '/services/:serviceID/status' => sub {
	my $serviceID = param( 'serviceID' );
	my $statusID = param( 'statusID' );	# passed in the POST content
	postStatus( $dbh, 'service', $serviceID, $statusID );
};

dance;
    
$dbh->disconnect;
