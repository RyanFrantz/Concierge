# TODO List
* Have postStatus() process dependencies and set upstream statuses as well
* Refactor all of the redundant SQL prepare() and execute() statements into a single module/method
* Write additional help/docs describing the available URLs/resources and their functions (Concierge::Help)
* Remove the $resource prefix from table columns such as appID in table app and serviceID in service.  It's unecessary and will make for cleaner SQL statements without them.
