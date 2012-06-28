#!/usr/bin/perl

package Concierge;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter);
our @EXPORT = qw( greeting getStatus getResource);
#our @EXPORT_OK = qw( greeting getStatus );

sub greeting {
	"Hello, World!\n\nI'm the App Status Dispatch a.k.a Concierge!\n";
}

sub getStatus {
	# get the status of the requested resource (app, host, service)
	my $dbh = shift;
	my $resource = shift;
	my $resourceID = shift;	# can be numeric or the word 'all'
	my $sql;
	$sql = qq{ SELECT DISTINCT ${resource}ID, ${resource}Name, ${resource}Description FROM ${resource} };
	$sql = qq{ SELECT DISTINCT ${resource}Name, ${resource}StatusDescription FROM ${resource} NATURAL JOIN ${resource}Status } if $resourceID eq "all";
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

	while ( my @row = $sth->fetchrow_array ) {
		print join( ' | ', @row ) . "\n";
	}
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

1;
