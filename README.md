# Concierge
## Purpose
Concierge is my attempt to build an easy to use RESTful web application to act as the smart glue between my monitoring stuff (Nagios, Splunk, logstash, db tools, etc) and a simple status dashboard that non-technical users can understand.

I originally wrote about this here: http://www.ryanfrantz.com/2012/07/10/concierge-he-knows-whats-up/.

Come see all the fun at http://status.ryanfrantz.com/.

## Extended Purpose
Recently one of my sysadmins [(jtslear)] (https://github.com/jtslear) asked me if Concierge, being so smart, would kindly recommend graphs for sysadmins to review in the event of a disruption or outage.  Previously, that had not been planned.  Now, it is.  Pow!

## Deployment
Current Concierge runs as a standalone script.  My plan is to use Apache to properly deploy the code in the future.  This is __very__ **ALPHA** at the moment.

## Design Choices
### Perl Dancer
This project uses Perl Dancer <http://perldancer.org/>.  I'm best at Perl.  Perl Dancer is based on the Sinatra project.

__I think I'm going to port this project to Ruby and use Sinatra. BTW.__

### SQLite
SQLite is fast and simple, two things I really want this project to be.

#### Table Names
The table names I selected are **singular**.  I usually prefer plural table names in designing tables (the content makes up a collection of the thing the table is named for), but I also like simple code.  So, to serve the latter, I use singular table names to make my code simpler.

### YAML
So that others can easily configure and use Concierge, I've select YAML to define the applications, services, and dependencies between the two.
