#!/usr/bin/perl

use lib "/root/concierge/lib";
use DBI;
use DBD::SQLite;
use DateTime;
use Data::Dumper;

# vars
my $db = '/root/concierge/sqlite/appStatus.db';
# no user/pass combo; we're using SQLite
my $user = "";
my $password = "";

# init before any requests
my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", $user, $password )
	or die "Unable to connect to SQLite database: " . DBI->errstr . "\n";
# subs

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
	# return either day information (i.e. Mon) or date information (YYYY-MM-DD)
	my $dayRange = shift;
	my $requestType = shift;	# 'days' or 'dates'
	# use today() ?
	my $days = [];
	my $dt = DateTime->now(
		time_zone	=>	'America/New_York',
	);

	my %daysOfWeek = (
		1	=>	'Mon',
		2	=>	'Tue',
		3	=>	'Wed',
		4	=>	'Thu',
		5	=>	'Fri',
		6	=>	'Sat',
		7	=>	'Sun',
	);

	# TODO: Clean up this redundant code!
	my $day_of_week = $dt->day_of_week;
	my $month = $dt->month_name;
	my $day = $dt->day;
	push @{ $days }, "$month $day ($daysOfWeek{ $day_of_week})" if $requestType eq 'days';
	$dt->set_time_zone( 'UTC' ) if $requestType eq 'dates';	# SQLite stores datetime values using UTC by default; we need to convert here; remains in effect until we leave this sub
	my $ymd = $dt->ymd;	# YYYY-MM-DD
	push @{ $days }, $ymd if $requestType eq 'dates';

	my $i = '1';
	while ( $i <= $dayRange ) {
		$dt->subtract( days => '1' );
		my $day_of_week = $dt->day_of_week;
		my $month = $dt->month_name;
		my $day = $dt->day;
		my $ymd = $dt->ymd;	# YYYY-MM-DD
		push @{ $days }, "$month $day ($daysOfWeek{ $day_of_week})" if $requestType eq 'days';	# junks up the display
		push @{ $days }, $ymd if $requestType eq 'dates';
		#push @{ $days }, "$month $day";
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
	my $numDays = '6';
	my $days = getDateRange( $numDays, 'days' );
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
					{image => 'icons/fugue/cross-circle.png' }, {image => 'icons/fugue/traffic-cone.png'}, {image => 'icons/fugue/cross-circle.png' }, {image => 'icons/fugue/tick-circle.png' }, {image => 'icons/fugue/cross-circle.png' }, {image => 'icons/fugue/tick-circle.png' }, {image => 'icons/fugue/tick-circle.png' }
				],
	 	};
		push @{ $vars->{ 'apps' } }, $hashref;
		#getStatusHistory() needs to return the proper array ref of hashes so we can pass it to the 'history' key
		#getEvents( $dbh, $resource, $ref->{"${resource}ID"}, '2012-09-05' );
	}

	return $vars;
	
}

sub getEvents {
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $date = shift;

	my $sql = qq{ SELECT eventDescription, eventDatetime FROM ${resource}Events WHERE ${resource}ID = $id AND eventDatetime LIKE "$date%" };
	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";
	$sth->execute()
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
	while ( my $ref = $sth->fetchrow_hashref ) {
		print "eventDescription: " . $ref->{ "eventDescription" } . "\n";
		print "eventDatetime: " . $ref->{ "eventDatetime" } . "\n";
	}

}

#getEvents( $dbh, 'app', '1', '2012-09-05' );

my $vars = getStatus( $dbh, 'app', 'all' );
#print Dumper $vars;
my $dates = getDateRange( '6', 'dates' );
#print Dumper $dates;

sub getStatusHistory {
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $dates = getDateRange( '6', 'dates' );

	my $sql = qq{ SELECT ${resource}StatusID, ${resource}StatusImage FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND eventDatetime LIKE ? ORDER BY eventDateTime ASC };
	# get the count of rows matching our query...
	my $sqlGetCount = qq{ SELECT COUNT( * ) FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND eventDatetime LIKE ? ORDER BY eventDateTime ASC };
	foreach my $date ( @{ $dates } ) {
		print "DATE: $date\n";
		my $sthGetCount = $dbh->prepare( $sqlGetCount )
			or die "Unable to prepare statement handle for \'$sqlGetCount\' " . $dbh->errstr . "\n";
		my $sth = $dbh->prepare( $sql )
			or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

		$sthGetCount->execute( "$date%" )
			or die "Unable to execute statement for \'$sqlGetCount\' " . $sth->errstr . "\n";
		$sth->execute( "$date%" )
			or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
		# ... if $rowCount == 0, there were no recorded events, set a default status for the day
		my $rowCount = $sthGetCount->fetchrow_array;
		#print "ROW COUNT: " . $rowCount . "\n";	# debug

		while ( my $ref = $sth->fetchrow_hashref ) {
		# if only a single event, return that status. if multiple, highest value wins; return that
			print "\t[" . $ref->{"${resource}StatusID"} . "] statusImage: " . $ref->{"${resource}StatusImage"} . "\n";
		}
		print "\t[1] statusImage: icons/fugue/tick-circle.png\n" if $rowCount == '0';
	}

}

getStatusHistory( $dbh, 'app', '1' );

$dbh->disconnect;
