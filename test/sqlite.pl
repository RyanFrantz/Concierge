#!/usr/bin/perl

use warnings;
use strict;

use DBI;
use DBD::SQLite;

my $db = '/root/concierge/sqlite/appStatus.db';
# no user/pass combo; we're using SQLite
my $user = "";
my $password = "";
my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", $user, $password )
	or die "Unable to connect to SQLite database: " . DBI->errstr . "\n";

#my $sql = qq{ SELECT * FROM apps };
# use NATURAL JOIN as we've named FKs to match the respective PKs
#my $sql = qq{ SELECT DISTINCT apps.appDescription, appStatusDescription FROM apps NATURAL JOIN appStatus };
my $sql = qq{ SELECT service.serviceName FROM service INNER JOIN service2app ON service.serviceID = service2app.serviceID WHERE service2app.appID = '2' };
my $sth = $dbh->prepare( $sql )
	or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";

$sth->execute()
	or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";

while ( my @row = $sth->fetchrow_array ) {
	print join( ' | ', @row ) . "\n";
}

$dbh->disconnect;
