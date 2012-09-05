sub getEvents {
	# get event history for specific app status page
	my $dbh = shift;
	my $resource = shift;
	my $id = shift;
	my $date = shift;
	my $events = [];

	my $sql = qq{ SELECT ${resource}StatusImage, message, datetime FROM ${resource}Events NATURAL JOIN ${resource}Status WHERE ${resource}ID = $id AND datetime LIKE "$date%" };
	my $sth = $dbh->prepare( $sql )
		or die "Unable to prepare statement handle for \'$sql\' " . $dbh->errstr . "\n";
	$sth->execute()
		or die "Unable to execute statement for \'$sql\' " . $sth->errstr . "\n";
	while ( my $ref = $sth->fetchrow_hashref ) {
		my $hashref = {
			datetime	=>	$ref->{ "datetime" },
			message		=>	$ref->{ "message" },
			statusImage	=>	$ref->{ "${resource}StatusImage" },
		};
		push @{ $events }, $hashref;
	}
	return $events

}
my $events = getEvents( $dbh, 'app', '1', '2012-09-05' );
print Dumper $events;
