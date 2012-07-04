# MUSINGS
* if dns1 DOWN
* find service deps
* DNS depends on dns1
* (determine rules to set status of DNS service)
 * if number of DNS hosts = 1, status = REDUNDANCY LOST
 * if number of DNS hosts = 0, status = DOWN
 *  >> don't need bridge table; perform status lookup of all hosts that DNS depends on and count WHERE status != UP? <<
* find app deps
* Clinician Desktop depends on DNS service
* (determine rules to set status of Clinician Desktop)
 * if DNS service status = REDUNDANCY LOST, status = Service Disruption
 * if DNS service status = DOWN, status = Service Outage
