#!/usr/bin/env perl

# Command line tool to work with database

use lib '.';
use DBUtil;
use feature 'say';
use Getopt::Long;
use Data::Dumper;
Getopt::Long::Configure("auto_version", "auto_help");

my %opts;
GetOptions (
	"a|action=s{1,2}" => \@{$opts{action}},
  "d|db=s" => \$opts{sqlite_database},
  "t|table=s" => \$opts{table},
  "v"  => \$opts{v}
) or die("Error in command line arguments\n");


my $db_loc = 'skud.db';
$db_loc=$opts{sqlite_database} if $opts{sqlite_database}; # location of database file relative to WORKDIR (/fabkey by default)
my $db = DBUtil->new(dbi =>'dbi:SQLite:dbname='.$db_loc);
say "Using SQLite database: ".$db_loc;

if ($opts{v}) {
	say "Getopt::Long options: ".Dumper \%opts;
}

sub create_tables {
	my $dbh = shift;

	# gpio_pin - pin of single board computer to which relay is attached
	# mac_addr - address of esp8266 module in case if door is connected wireless
	# opening_script - you can set custom opening bash script for each door (useful in case if one reader need open two doors with delay)\
	# reader_port - port of hardware Wiegand reader attached to particular door
	# users_restricted - door can be opened only by particular users (see permissions table)
	# Priority: opening_script, gpio_pin, mac_addr

	my $sql = <<'END_SQL';
CREATE TABLE doors (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	created DEFAULT CURRENT_TIMESTAMP,
		name VARCHAR(160),
		gpio_pin INTEGER(2),
		mac_addr VARCHAR(12),
		opening_script VARCHAR(255),
		card_reader_port VARCHAR(255),
		is_users_restricted VARCHAR(1),
		state_pin INTEGER(2)
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
    pin INTEGER(4),
    name VARCHAR(160),
    surname VARCHAR(160),
		phone VARCHAR(12),
    email VARCHAR(160),
		is_blocked INTEGER,
		is_admin INTEGER
    )
END_SQL
    $dbh->do($sql);

	return 0;
}




if ($opts{action}[0] eq 'deploy_db') {
  create_tables($db->dbh);
  say "Database was created!";
}


if ($opts{action}[0] eq 'demo_data') {

  my %user1 = (
         card_id=> 7357893,
         pin=> 1234,
         name=>'OnlyCardUser',
         email=>'pavelsr@cpan.org',
         phone=>'+78633090549'
      );
  my %user2 = (
      name=>'OnlyTelegramUser',
      telegram_id=> 218718957
  );

  $db->add_to_db( \%user1 ,'users');
  $db->add_to_db( \%user2 ,'users');

  say "Added two demo users";

  my %door1 = (
         name=> "Main door",
         gpio_pin=> 22
      );

  my %door2 = (
        name=> "Door 2",
        opening_script=> 'data/main_door_with_delay.sh'  # in data location
    );

  $db->add_to_db( \%door1 ,'doors');
  $db->add_to_db( \%door2 ,'doors');
  say "Added two demo doors";
}



if ($opts{action}[0] eq 'manage') {
  if (($opts{table} eq 'users') && ($opts{action}[1] eq 'add')) {
    # add user to database
    my $ahash = {};
    my @required_fields = ('card_id', 'telegram_id', 'pin', 'name', 'surname', 'email', 'phone');
  	for (@required_fields) {
  		print $_.":";
  		$ahash->{$_}=<STDIN>;
  		chomp($ahash->{$_});
  	}
    $db->add_to_db($ahash,'users');
  }
}



=head1 USAGE

db.pl -a deploy_db

db.pl -a demo_data

db.pl [-d data/test.db] -a deploy_db

db.pl [-d data/test.db] -a manage [add|block|remove|show] -t users

OPTIONS:

-a, --action [deploy_db|demo_data|manage]   Action

-d, --db  You can manually specify path to database to work with. By default it's skud.db

-t, --table Table to use in manage


=cut
