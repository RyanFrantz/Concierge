#!/usr/bin/perl

package Concierge;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter);
our @EXPORT = qw( greeting getStatus getStatusTypes getDateRange getResource postStatus getDeps );

use Template;
use DateTime;

#sub greeting {
#	"Hello, World!\n\nI'm the App Status Dispatch a.k.a Concierge!\n";
#}

sub greeting {
	my $vars = {
		name		=>	'Ryan',
		title		=>	'Concierge',
		logout_url	=>	'logout.html',
	};
	return $vars;
}

sub getStatusTypes {
	# get the status of the requested resource (app, host, service)
	my $dbh = shift;
	my $resource = shift;
	my $sql;
	$sql = qq{ SELECT ${resource}StatusDescription, ${resource}StatusImage FROM ${resource}Status };

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute()
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	my $statuses = [];
	while ( my $ref = $sth->fetchrow_hashref ) {
		my $hashref = {
			image => $ref->{"${resource}StatusImage"},
			description => $ref->{"${resource}StatusDescription"},
		};
		push @{ $statuses }, $hashref;
	}

	return $statuses;
	
}

sub getDateRange {
	my $dayRange = shift;
	# use today() ?
	my $days = [];
	my $dt = DateTime->now(
		time_zone	=>	'America/New_York',
	);

	my $month = $dt->month_name;
	my $day = $dt->day;
	push @{ $days }, "$month $day";
	#print "$month $day" . "\n";

	my $i = '1';
	while ( $i <= $dayRange ) {
		$dt->subtract( days => '1' );
		my $month = $dt->month_name;
		my $day = $dt->day;
		push @{ $days }, "$month $day";
		#print "$month $day" . "\n";
		$i++;
	}

	return $days;

}

sub getStatus {
	# get the status of the requested resource (app, host, service)
	my $dbh = shift;
	my $resource = shift;
	my $resourceID = shift;	# can be numeric or the word 'all'
	my $sql;
	$sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}Name, ${resource}Description FROM ${resource} };
	$sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}Name, ${resource}StatusDescription, ${resource}StatusImage FROM ${resource} NATURAL JOIN ${resource}Status } if $resourceID eq "all";
	$sql = qq{ SELECT DISTINCT ${resource}.${resource}Name, ${resource}StatusDescription FROM ${resource} NATURAL JOIN ${resource}Status WHERE ${resource}.${resource}ID = ? } if $resourceID =~ /\d+/;

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	if ( $resourceID =~ /\d+/ ) {
		$sth->execute( $resourceID )
			or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
	} else {
		$sth->execute()
			or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
	}

	# get status types for the given resource type
	my $statuses = getStatusTypes( $dbh, $resource );
	my $days = getDateRange( '6' );
	my $vars = {
		title => 'Concierge',
		days => $days,
		apps => [],
		statuses => $statuses,
	};

	while ( my $ref = $sth->fetchrow_hashref ) {
		my $hashref = { 
				name => $ref->{"${resource}Name"},
				id => $ref->{"${resource}ID"},
				statusImage => $ref->{"${resource}StatusImage"},
				statusDescription => $ref->{"${resource}StatusDescription"},
				history => [
					{image => 'icons/fugue/cross-circle.png' }, {image => 'icons/fugue/hard-hat.png'}
				],
	 	};
		push @{ $vars->{ 'apps' } }, $hashref;
	}

	return $vars;
	
}

sub postStatus {
	# update the status of the requested resource (app, host, service)
	my $dbh = shift;
	my $resource = shift;
	my $resourceID = shift;	# numeric
	return unless $resourceID =~ /\d+/;	# only numeric args here!
	my $statusID = shift;
	my $sql;
	$sql = qq{ UPDATE ${resource} SET ${resource}StatusID = ? WHERE ${resource}ID = ? };
	#print $sql . " $statusID, $resourceID\n";	# debug

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute( $statusID, $resourceID )
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	# TODO: have postStatus() process dependencies and set upstream statuses as well
	processDeps();	# much planning to do here...

	# TODO: return something useful on error...
	print "\n";
}

sub getResource {
	# get and return a list of items of type $resource
	my $dbh = shift;
	my $resource = shift;
	my $sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}Name, ${resource}Description FROM ${resource} };
	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute()
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	while ( my @row = $sth->fetchrow_array ) {
		print join( ' | ', @row ) . "\n";
	}
	print "\n";
}

sub getDeps {
	# get the dependencies of the requested resource (host, service)
	# answer the question: which $thing[s] depend on $resource?
	#  NOT: which $thing[s] does $resource depend on?
	my $dbh = shift;
	my $resource = shift;
	my $resourceID = shift;	# numeric
	return unless $resourceID =~ /\d+/;	# only numeric args here!
	my $sql;
	$sql = qq{ SELECT service.serviceID, service.serviceName FROM service INNER JOIN host2service ON service.serviceID = host2service.serviceID WHERE host2service.hostID = ? } if $resource =~ /host/;
	$sql = qq{ SELECT app.appID, app.appName FROM app INNER JOIN service2app ON app.appID = service2app.appID WHERE service2app.serviceID = ? } if $resource =~ /service/;

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute( $resourceID )
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	while ( my @row = $sth->fetchrow_array ) {
		print join( ' | ', @row ) . "\n";
	}
	print "\n";
}

sub processDeps {
	# process dependencies and update status accordingly
	# 1. determine the appropriate upstream resource (i.e. host -> service; service -> app)
	# 2. getDeps()
	# 3. postStatus()
	# 4. updateDashboard() << here? or outside of processDeps()?
}

sub getServiceStatus2AppStatusRules {
	# I may want the below SQL at some point to GET the rules/relationships between
	# the service status and app status, in plain English
	# i.e. if service status = 'REDUNDANCY LOST', app status = 'Service disruption'
	my $sql;
	$sql = qq{ SELECT serviceStatus.serviceStatusDescription, appStatus.appStatusDescription FROM serviceStatus2appStatus
 INNER JOIN serviceStatus ON serviceStatus2appStatus.serviceStatusID = serviceStatus.serviceStatusID
 INNER JOIN appStatus ON serviceStatus2appStatus.appStatusID = appStatus.appStatusID };
}

1;
