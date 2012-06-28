#!/usr/bin/perl

package Concierge::Help;

use warnings;
use strict;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( getHelp );
our @EXPORT_OK = qw( getHelp );

sub getHelp {
	print "\n-- apps\n";
	print "/apps > list all defined applications that are being monitored\n";
	print "/apps/all/status > list the status for all defined applications that are being monitored\n";
	print "/apps/{appID}/status > list the status for application {appID}\n";
	print "\n\tEXAMPLE: /apps/1/status\n";
	print "\n-- help\n";
	print "/help > this URL and related help information\n";
	print "\n-- hosts\n";
	print "/hosts > list all defined hosts that are being monitored\n";
	print "/hosts/all/status > list the status for all defined hosts that are being monitored\n";
	print "\n-- services\n";
	print "/services > list all defined services that are being monitored\n";
	print "/services/all/status > list the status for all defined services that are being monitored\n";
	print "\n";
}

1;
