package DBUtil;

# Finctions to work with database. Currently works only with SQLite

use DBI;
use strict;
use DBD::SQLite;
use DBD::SQLite::Constants qw/:file_open/;
use Data::Dumper; # leave only for debug

=head1 Usage

  my $dbh = DBI->connect("dbi:SQLite:dbname=skud.db","","");
  my $db = DBUtil->new(dbh => $dbh);

=cut

sub new {
    my ($class, %args) = @_;
    $args{'dbh'} = DBI->connect($args{'dbi'},"","", $args{'flags'});
    $args{'gpio_script'} = './open_gpio.sh';
    $args{'wireless_script'} = './open_wireless.sh';
    return bless \%args, $class;
}

sub dbh { shift->{dbh} }

sub construct_or_statement {
  my ($self, %kv) = @_; # %kv - key-value hash
  my $str = '('.(keys %kv)[0].'=\''.(values %kv)[0].'\')';
  delete $kv{(keys %kv)[0]};
  while (my ($key, $value) = each %kv) {
    $str = join('OR', $str, '('.$key.'=\''.$value.'\')');
  }
  return $str;
}


sub construct_update_statement { # just comma-separated values
  my ($self, %kv) = @_; # %kv - key-value hash
  my $str = (keys %kv)[0].'=\''.(values %kv)[0].'\'';
  delete $kv{(keys %kv)[0]};
  while (my ($key, $value) = each %kv) {
    $str = join(',', $str, ' '.$key.'=\''.$value.'\'');
  }
  return $str;
}


sub update_table_item {
  my ($self, $table, %updated_fields, %where_kv) = @_;
  # warn "Where key val ".Dumper \%where_key_val;
  my $set = $self->construct_update_statement(%updated_fields);
  my $where = (keys %where_kv)[0]."=\'".(values %where_kv)[0]."\'";
  # warn "Where str ".Dumper $where;
  my $sql_cmd = "UPDATE ".$table." SET ".$set." WHERE ".$where;
  warn Dumper $sql_cmd;
  warn Dumper $self->dbh->do($sql_cmd) or die $self->{dbh}->errstr;
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


sub search_in_table {
	my ($self, $table_name, %kv) = @_;  # $kv - key & value
  $self->{dbh}->selectrow_hashref('SELECT * FROM '.$table_name.' WHERE '.$self->construct_or_statement(%kv));   # need to call from DBI::st instead of DBI::db
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
  warn "Door info".Dumper $res;
  if (defined $res) {
    if ($res->{opening_script}) {
      if (-e $res->{opening_script}) {
        return `$res->{opening_script}`;
      } else {
        return "No such opening_script: ".$res->{opening_script};
      }
    } elsif ($res->{gpio_pin}){
      return `$self->{gpio_script} $res->{gpio_pin}`;  # use default script for gpio
    } elsif ($res->{mac_addr}) {
      if (-e $res->{opening_script}) {
        return `$self->{wireless_script} $res->{mac_addr}`;
      } else {
        return "No such wireless_script: ".$res->{opening_script};
      }
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
  my $res = $self->{dbh}->selectrow_hashref('SELECT is_users_restricted FROM doors WHERE id ='.$door_id);
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


=head1 authorize_user

Perhaps the main function of business logic

=cut


sub authorize_user {
  my ($self, $params) = @_;   # $params - hash. Return string
  if (!exists $params->{telegram_username} && !exists $params->{telegram_id} && !exists $params->{card_id}) {
    return 'Not enough parameters provided: telegram_username or telegram_id or card_id';
  }
  my @a =  qw/door_id pin/; # essential parameters
  my @absent_params;
  for (@a) {
    if (!$params->{$_}) {
      push @absent_params, $_;
    }
  }
  if (@absent_params) {
    return 'Not enough parameters provided: '.join(', ',@absent_params);
  }

  my %filtered_params = map { $_ => $params->{$_} } grep { exists $params->{$_} } qw/telegram_id card_id telegram_username/; # all unique indexes
  warn "User search criterias: ".Dumper \%filtered_params;
  my $user = $self->search_user_in_db(%filtered_params);
  warn "User found: ". Dumper $user;

  if (%$user)  {
    if ($self->is_door_restricted($params->{door_id})) {  # not implemented yet. or substitute it with table_info
      my $perm = $self->door_permissions_all($params->{door_id});
      warn "All door permissions: ".Dumper $perm;
      return "Door is restricted for particular users. But check code is not implemented yet :)"
    } else { # door is common
      if ($user->{pin} eq $params->{pin}) {
        return $self->open_door($params->{door_id});
      } else {
        return 'Wrong password!';
      }
    }

    } else {
        return 'User is not found in database';
    }
}


sub prepare_sql {
    my ($self, $hash) = @_;
    my @fields;
    my @values;
    foreach my $key ( keys %$hash ) {
        if ($hash->{$key}) {
          push @fields, $key;
          push @values, "'".$hash->{$key}."'";
        }
    }
    my $new_hash;
    $new_hash->{'fields'} = join(", ", @fields);
    $new_hash->{'values'} = join(", ", @values);
    return $new_hash;
}


sub add_to_db {
    my ($self, $hash, $table_name) = @_;
    my $h = $self->prepare_sql($hash);
    $self->{dbh}->do("INSERT INTO ".$table_name." (".$h->{'fields'}.") VALUES (".$h->{'values'}.")") or die $self->{dbh}->errstr;
    return 0;
}


# return ordered arrayref

sub column_names {
  my ($self, $table_name) = @_;
  return $self->{dbh}->prepare('SELECT * FROM '.$table_name)->{NAME};
}


# like a https://metacpan.org/pod/Term::Form

sub ask_for_values {
    my ($self, $fields_array) = @_;
    my $result;
    for (@$fields_array) {
  		print $_.": ";
  		$result->{$_}=<STDIN>;
  		chomp($result->{$_});
  	}
    return $result;
}

sub is_command_standart {
    my ($self, $commamnd) = @_;
    if (grep { $commamnd eq $_ } qw/insert update delete/ ) { return 1; } else { return 0; }
}


# Algorithm is simpe. If number of entries of user is odd - user is in

sub users_in {
    my $self = shift;
    # my $entries = $self->{dbh}->do('SELECT * FROM entries GROUP BY user_id');
    my $entries = $self->{dbh}->selectall_hashref('SELECT * FROM entries', 'id');
    my $clusterized_entries = {};
    for (values %$entries) {
      $clusterized_entries->{$_->{user_id}} ++;
    }
    warn Dumper $clusterized_entries;
    # select idd user id
    my @ids_in;
    while (my ($key, $value) = each %$clusterized_entries) {
      if ($value % 2 == 1) {
        push @ids_in, $key;
      }
    }
    # return \@ids_in;
    my $msg_str;
    for (@ids_in) {
      if ($_) { # protection from non-empty id string
        my $info = $self->search_in_table('users', id => $_);
        # warn Dumper $info;
        if ($info->{name} && $info->{surname}) {
          $msg_str = $msg_str.'@'.$info->{telegram_username}." ".$info->{name}." ".$info->{surname}."\n";
        } else {
          $msg_str = $msg_str.'@'.$info->{telegram_username}."\n";
        }
      }
    }
    return $msg_str;
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
