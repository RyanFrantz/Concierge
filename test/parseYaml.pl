#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use YAML qw (LoadFile );

my $yaml = 'init/init.yaml';

my $ref = LoadFile( $yaml );

print Dumper $ref;
