#!/usr/bin/perl

package Concierge;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter);
our @EXPORT = qw( greeting getStatus getStatusHistory getStatusTypes getDateRange getEvents getResource postStatus postEvent getDeps );

use Template;
use DateTime;

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
	my $ymd = $dt->ymd;	# YYYY-MM-DD
	push @{ $days }, "$month $day<br>($daysOfWeek{ $day_of_week})" if $requestType eq 'days';
	push @{ $days }, $ymd if $requestType eq 'dates';

	my $i = '1';
	while ( $i <= $dayRange ) {
		$dt->subtract( days => '1' );
		my $day_of_week = $dt->day_of_week;
		my $month = $dt->month_name;
		my $day = $dt->day;
		my $ymd = $dt->ymd;	# YYYY-MM-DD
		push @{ $days }, "$month $day<br>($daysOfWeek{ $day_of_week})" if $requestType eq 'days';	# junks up the display
		push @{ $days }, $ymd if $requestType eq 'dates';
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
	$sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}.${resource}Name, ${resource}StatusDescription, ${resource}StatusImage FROM ${resource} NATURAL JOIN ${resource}Status WHERE ${resource}.${resource}ID = ? } if $resourceID =~ /\d+/;

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
	#my $days = getDateRange( $numDays, 'days' );
	my $days = getDateRange( $numDays, 'dates' );
	my $vars = {
		title => 'Concierge',
		days => $days,
		apps => [],
		statuses => $statuses,
	};

	while ( my $ref = $sth->fetchrow_hashref ) {
		my $history = getStatusHistory( $dbh, $resource, $ref->{"${resource}ID"} );
		my $hashref = { 
				name => $ref->{"${resource}Name"},
				id => $ref->{"${resource}ID"},
				currentStatusImage => $ref->{"${resource}StatusImage"},
				history => $history
	 	};
		push @{ $vars->{ 'apps' } }, $hashref;
	}

	return $vars;
	
}

sub getStatusHistory {
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $dates = getDateRange( '6', 'dates' );
	my $history = [];

	# get a row count for our query
	my $sqlGetRowCount = qq{ SELECT COUNT( * ) FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND datetime >= ? AND datetime <= ? ORDER BY datetime ASC };
	# return all events except 'OK/Available' events so that we can determine the ultimate icon to use on the main page
	my $sql = qq{ SELECT ${resource}StatusID, ${resource}StatusImage FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND datetime >= ? AND datetime <= ? AND ${resource}StatusID != '1' };
	foreach my $date ( @{ $dates } ) {
		my $datetimeStart = $date . " 00:00:00";
		my $datetimeEnd = $date . " 23:59:59";
		my $datetimeStartUTC = getDatetimeUTC( $datetimeStart );
		my $datetimeEndUTC = getDatetimeUTC( $datetimeEnd );
		my $sthGetCount = $dbh->prepare( $sqlGetRowCount )
			or die "Unable to prepare statement handle for \'$sqlGetRowCount\' " . $dbh->errstr . "\n";
		$sthGetCount->execute( $datetimeStartUTC, $datetimeEndUTC )
			or die "Unable to execute statement for \'$sqlGetRowCount\' " . $sthGetCount->errstr . "\n";
		# if $rowCount == 0, there were no recorded events, set a default status for the day
		my $rowCount = $sthGetCount->fetchrow_array;
		if ( $rowCount == '0' ) {
			my $hashref = {
				image	=>	'icons/fugue/tick-circle.png',	# default, happy
				date	=>	$date,
			};
			push @{ $history }, $hashref;
		} else {

			my $sth = $dbh->prepare( $sql )
				or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";
			$sth->execute( $datetimeStartUTC, $datetimeEndUTC )
				or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

			my %id2Image;
			while ( my $ref = $sth->fetchrow_hashref ) {
				$id2Image{ $ref->{"${resource}StatusID"} } = $ref->{"${resource}StatusImage"};
			}

			# set the ultimate status icon according to the below rules; these define the severity of the status' it's not elegant, but it works
			my @severityOrder = ( 3, 2, 4 );
			foreach my $statusID ( @severityOrder ) {
				if ( exists $id2Image{ $statusID } ) {
					my $hashref = {
						image	=>	$id2Image{ $statusID },
						date	=>	$date,
					};
					push @{ $history }, $hashref;
					last;
				}
			}
		}
	}

	return $history;

}

sub getDatetimeUTC {

	# return a datetime string in the UTC time zone for use in database queries
	my $datetime = shift;
	# parse the date so that we can localize if for our time zone (SQLite stores default datetimes in UTC)
	my ($year, $month, $day, $hour, $minute, $second);
	($year = $1, $month = $2, $day = $3, $hour = $4, $minute = $5, $second = $6) if $datetime =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
	my $dt = DateTime->new(
		year	=> 	$year,
		month	=>	$month,
		day	=>	$day,
		hour	=>	$hour,
		minute	=>	$minute,
		second	=>	$second,
		time_zone	=>	'America/New_York',
	);
	$dt->set_time_zone( 'UTC' );
	my $datetimeUTC = $dt->ymd('-') . " " . $dt->hms;
	return $datetimeUTC;

}

sub getEvents {
	# get event history for specific app status page
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $datetime = shift;

	my $vars;
        my $statuses = getStatusTypes( $dbh, $resource );
	my $app = getResource( $dbh, 'app', $id );
	my $events = [];
	my ( $datetimeStart, $datetimeEnd, $datetimeStartUTC, $datetimeEndUTC );
	unless ( $datetime eq 'all' ) {
		$datetimeStart = $datetime . " 00:00:00";
		$datetimeEnd = $datetime . " 23:59:59";
		$datetimeStartUTC = getDatetimeUTC( $datetimeStart );
		$datetimeEndUTC = getDatetimeUTC( $datetimeEnd );
	}

	my ( $sqlGetRowCount, $sql );
	$sqlGetRowCount = qq{ SELECT COUNT(*) FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND datetime >= "$datetimeStartUTC" AND datetime <= "$datetimeEndUTC" } if $datetime =~ /\d{4}-\d{2}-\d{2}/;
	$sqlGetRowCount = qq{ SELECT COUNT(*) FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id } if $datetime eq 'all';
	$sql = qq{ SELECT ${resource}StatusImage, message, datetime FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND datetime >= "$datetimeStartUTC" AND datetime <= "$datetimeEndUTC" ORDER BY datetime DESC } if $datetime =~ /\d{4}-\d{2}-\d{2}/;
	$sql = qq{ SELECT ${resource}StatusImage, message, datetime FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id ORDER BY datetime DESC LIMIT 10 } if $datetime eq 'all';

	my $sthGetRowCount = $dbh->prepare( $sqlGetRowCount )
		or die "Unable to prepare statement handle for \'$sqlGetRowCount\' " . $dbh->errstr . "\n";
	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sthGetRowCount->execute()
		or die "Unable to execute statement for \'$sqlGetRowCount\' " . $sthGetRowCount->errstr . "\n";
	my $rowCount = $sthGetRowCount->fetchrow_array;
	$datetime = 'All Events' if $datetime eq 'all';
	if ( $rowCount != '0' ) {
		$sth->execute()
			or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
		while ( my $ref = $sth->fetchrow_hashref ) {
			# parse the date so that we can localize if for our time zone (SQLite stores default datetimes in UTC)
			my ($year, $month, $day, $hour, $minute, $second);
			($year = $1, $month = $2, $day = $3, $hour = $4, $minute = $5, $second = $6) if $ref->{ "datetime" } =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
			my $dt = DateTime->new(
				year	=> 	$year,
				month	=>	$month,
				day	=>	$day,
				hour	=>	$hour,
				minute	=>	$minute,
				second	=>	$second,
				time_zone	=>	'UTC',
			);
			$dt->set_time_zone( 'America/New_York' );
			my $adjustedDatetime = $dt->ymd('-') . " " . $dt->hms;
			my $hashref = {
				#datetime	=>	$ref->{ "datetime" },
				datetime	=>	$adjustedDatetime,
				message		=>	$ref->{ "message" },
				statusImage	=>	$ref->{ "${resource}StatusImage" },
			};
			push @{ $events }, $hashref;
		}
		$vars = {
			title	=>	'Concierge',
			date	=>	$datetime,
			app	=>	$app,
			events	=>	$events,
			statuses => $statuses,
		};
	} else {
		$vars = {
			title	=>	'Concierge',
			date	=>	$datetime,
			app	=>	$app,
			#events	=>	$events,	# don't send an empty 'events' key
			statuses => $statuses,
		};
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

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute( $statusID, $resourceID )
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	# TODO: have postStatus() process dependencies and set upstream statuses as well
	processDeps();	# much planning to do here...

	# TODO: return something useful on error...
}

sub postEvent {
	# update the status of the requested resource (app, host, service)
	my $dbh = shift;
	my $resource = shift;
	my $resourceID = shift;	# numeric
	return unless $resourceID =~ /\d+/;	# only numeric args here!
	my $statusID = shift;
	my $message = shift;
	my $sql;
	$sql = qq{ INSERT INTO ${resource}Events ( ${resource}ID, ${resource}StatusID, message ) VALUES (?, ?, ?) };

	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute( $resourceID, $statusID, $message )
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	# update the current status of the resource
	postStatus( $dbh, $resource, $resourceID, $statusID );
}

sub getResource {
	# get and return a list of items of type $resource
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $result = [];

	my $sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}Name, ${resource}Description FROM ${resource} WHERE ${resource}ID = $id };
	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

	$sth->execute()
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

	while ( my $ref = $sth->fetchrow_hashref ) {
		my $hashref = {
			name		=>	$ref->{ "${resource}Name" },
			description	=>	$ref->{ "${resource}Description" },
		};
		push @{ $result }, $hashref;
	}
	return $result;
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
