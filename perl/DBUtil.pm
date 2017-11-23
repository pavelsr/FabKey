package DBUtil;

# Finctions to work with database. Currently works only with SQLite

use DBI;
use strict;
use DBD::SQLite;

=head1 Usage

  my $dbh = DBI->connect("dbi:SQLite:dbname=skud.db","","");
  my $db = DBUtil->new(dbh => $dbh);

=cut

sub new {
    my ($class, %args) = @_;
    $args{'dbh'} = DBI->connect($args{'dbi'},"","");
    warn "New args: ".Dumper \%args;
    return bless \%args, $class;
}


=head1 search_user_in_db

Search user in DB. Search by only one criteria (provided hash can have only one item)

Return ONLY ONE RESULT (like https://metacpan.org/pod/DBI#fetchrow_hashref)

Usage examples:

  search_user_in_db(telegram_username => 'serikoff');
  search_user_in_db(card_id => '12345678');

=cut


sub search_user_in_db {
	my ($self, %kv) = @_;  # $kv - key & value
  my $search = {
    field => (keys %kv)[0],
    value => (values %kv)[0]
  };
  my $sth = $self->{dbh}->prepare("SELECT * FROM users WHERE ".$search->{field}." = ?")  or die $self->{dbh}->errstr;
	$sth->execute($search->{value});
	my $hash_ref = $sth->fetchrow_hashref;
	return $hash_ref;
}


1;
