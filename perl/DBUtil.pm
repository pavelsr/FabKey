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
