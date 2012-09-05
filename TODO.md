# TODO List
* Have postStatus() process dependencies and set upstream statuses as well
* Refactor all of the redundant SQL prepare() and execute() statements into a single module/method
* Write additional help/docs describing the available URLs/resources and their functions (Concierge::Help)
* Remove the $resource prefix from table columns such as appID in table app and serviceID in service.  It's unecessary and will make for cleaner SQL statements without them.
* Check the events table for the latest status "today" to dynamically set the icon under the "Current" column (i.e. search events by date in DESC order, LIMIT 1).
* Make sure the datetime value pulled out of SQLite is localized properly, at least for me.
* MAJOR: Concierge doesn't appear to notice when the database gets updated!  Fix this!
