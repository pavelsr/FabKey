package DBUtil;

# Finctions to work with database. Currently works only with SQLite

use DBI;
use strict;
use DBD::SQLite;
# use Data::Dumper;

=head1 Usage

  my $dbh = DBI->connect("dbi:SQLite:dbname=skud.db","","");
  my $db = DBUtil->new(dbh => $dbh);

=cut

sub new {
    my ($class, %args) = @_;
    $args{'dbh'} = DBI->connect($args{'dbi'},"","");
    $args{'gpio_script'} = './open_gpio.sh';
    $args{'wireless_script'} = './open_wireless.sh';
    return bless \%args, $class;
}

sub construct_or_statement {
  my ($self, %kv) = @_; # %kv - key-value hash
  my $str = '('.(keys %kv)[0].'=\''.(values %kv)[0].'\')';
  delete $kv{(keys %kv)[0]};
  while (my ($key, $value) = each %kv) {
    $str = join('OR', $str, '('.$key.'=\''.$value.'\')');
  }
  return $str;
}



=head1 search_user_in_db

Search user in DB. Search by multiple criterias (OR logic for each)

Return ONLY ONE RESULT (like https://metacpan.org/pod/DBI#selectrow_hashref)

Usage examples:

  search_user_in_db(telegram_username => 'serikoff');
  search_user_in_db(card_id => '12345678');
  search_user_in_db(telegram_username => 'serikoff', card_id => '12345678');

=cut


sub search_user_in_db {
	my ($self, %kv) = @_;  # $kv - key & value
  $self->{dbh}->selectrow_hashref('SELECT * FROM users WHERE '.$self->construct_or_statement(%kv));   # need to call from DBI::st instead of DBI::db
}



=head1 door_permissions_all

Return all door permissions

=cut


sub door_permissions_all {
	my ($self, $door_id) = @_;  # $kv - key & value
  $self->{dbh}->selectall_hashref('SELECT * FROM permissions WHERE door_id ='.$door_id, 'id');
}


=head1 is_user_allowed_door

Check is user allowed to use particular door

=cut



sub is_user_allowed_door {
	my ($self, %params) = @_;  # $kv - key & value
  my $res = $self->{dbh}->selectrow_hashref('SELECT * FROM permissions WHERE door_id='.$params{door_id}.' AND user_id='.$params{user_id});
  if (%$res) { return 1 } else { return 0 };
}


=head1 is_user_allowed_door

Check is user allowed to use particular door

=cut


sub open_door {
	my ($self, $door_id) = @_;  # $kv - key & value
  my $res = $self->{dbh}->selectrow_hashref('SELECT * FROM doors WHERE id='.$door_id);
  if (defined $res) {
    if ($res->{opening_script}) {
      return `$res->{opening_script}`;
    } elsif ($res->{gpio_pin}){
      return `$self->{gpio_script} $res->{gpio_pin}`;  # use default script for gpio
    } elsif ($res->{mac_addr}) {
      return `$self->{wireless_script} $res->{mac_addr}`;
    } else {
      return "No door opening definition";
    }
  } else { return "Door is undefined"; }
}


=head1 is_door_restricted

Return all door permissions

=cut


sub is_door_restricted {
	my ($self, $door_id) = @_;  # $kv - key & value
  my $res = $self->{dbh}->selectrow_hashref('SELECT is_users_restricted FROM door WHERE id ='.$door_id);
  if ($res->{is_users_restricted }) { return 1; } else { return 0; }
}


=head1 available_doors

Return all available for this user doors

=cut


sub available_doors {
	my ($self, $user_id) = @_;  # $user_id is optional
  my $res = $self->{dbh}->selectall_hashref('SELECT * FROM doors', 'id');
}




sub get_door_id_by_name {
  my ($self, $name_str) = @_;  # $user_id is optional
  $self->{dbh}->selectrow_hashref('SELECT id FROM doors WHERE name = '.$name_str)->{id};
}


sub get_door_info_by_name {
  my ($self, $name_str) = @_;  # $user_id is optional
  $self->{dbh}->selectrow_hashref('SELECT * FROM doors WHERE name= \''.$name_str.'\'');
}


### OLD CODE


# =head1 search_user_in_db
#
# Search user in DB. Search by only one criteria (provided hash can have only one item)
#
# Return ONLY ONE RESULT (like https://metacpan.org/pod/DBI#fetchrow_hashref)
#
# Usage examples:
#
#   search_user_in_db(telegram_username => 'serikoff');
#   search_user_in_db(card_id => '12345678');
#
# =cut

# sub search_user_in_db {
# 	my ($self, %kv) = @_;  # $kv - key & value
#   my $search = {
#     field => (keys %kv)[0],
#     value => (values %kv)[0]
#   };
#   my $sth = $self->{dbh}->prepare("SELECT * FROM users WHERE ".$search->{field}." = ?")  or die $self->{dbh}->errstr;
# 	$sth->execute($search->{value});
#    warn "STH: ".Dumper $sth;
# 	my $hash_ref = $sth->fetchrow_hashref;
# 	return $hash_ref;
# }


1;
