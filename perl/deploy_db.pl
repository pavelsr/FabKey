#!/usr/bin/env perl

# Creates SQLite database with needed structure
# to run it please install DBD::SQLite firstly

# to view Database
# sudo apt-get install sqlitebrowser

use DBI;
use feature 'say';
use Data::Dumper;

my $dbh = DBI->connect('dbi:SQLite:dbname=skud.db',"","");

create_tables($dbh);

sub create_tables {
	my $dbh = shift;

	# gpio_pin - pin of single board computer to which relay is attached
	# mac_addr - address of esp8266 module in case if door is connected wireless
	# opening_script - you can set custom opening bash script for each door (useful in case if one reader need open two doors with delay)\
	# reader_port - port of hardware Wiegand reader attached to particular door
	# users_restricted - door can be opened only by particular users (see permissions table)

	my $sql = <<'END_SQL';
CREATE TABLE doors (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	created DEFAULT CURRENT_TIMESTAMP,
		door_id INTEGER,
		name VARCHAR(160),
		gpio_pin INTEGER(2),
		mac_addr VARCHAR(12),
		opening_script VARCHAR(255),
		reader_port VARCHAR(255),
		users_restricted VARCHAR(1)
		)
END_SQL
	$dbh->do($sql);

# Permissions of users_restricted doors

	my $sql = <<'END_SQL';
CREATE TABLE permissions (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	created DEFAULT CURRENT_TIMESTAMP,
		door_id INTEGER,
		user_id INTEGER
		)
END_SQL
	$dbh->do($sql);

# Log of all calls to FabKey (even failed)

	my $sql = <<'END_SQL';
CREATE TABLE log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	time DEFAULT CURRENT_TIMESTAMP,
    door_id INTEGER,
    pin INTEGER,
    source VARCHAR(4),
    user_id INTEGER
    )
END_SQL
	$dbh->do($sql);

# Log of successful entries

    my $sql = <<'END_SQL';
CREATE TABLE entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    time DEFAULT CURRENT_TIMESTAMP,
    door_id INTEGER,
    user_id INTEGER
    )
END_SQL
    $dbh->do($sql);

# Users table
# Added ability to block users (is_blocked field)

	$sql = <<'END_SQL';
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created DEFAULT CURRENT_TIMESTAMP,
    card_id INTEGER,
		telegram_id INTEGER,
		telegram_username VARCHAR(160),
    pin INTEGER,
    name VARCHAR(160),
    surname VARCHAR(160),
		phone VARCHAR(12),
    email VARCHAR(160),
		is_blocked INTEGER
    )
END_SQL
    $dbh->do($sql);

	return 0;
}
