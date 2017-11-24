#!/usr/bin/env perl

## Mojolicious server with API

use Mojolicious::Lite;
use feature 'say';
use Data::Dumper;
use DBUtil;
use Mojolicious::Plugin::JSONConfig;

my $config = plugin JSONConfig => {file => 'config.json'};
# + replace config with ENV variables for easy dockerizing

my $db = DBUtil->new(dbi => $config->{"DBI"});
app->log->debug("USing database: ".$config->{"DBI"});

get '/' => sub {
  my $c = shift;
  $c->render(json => 'Server is running');
};

# Essential params are:
# telegram_username
# door_id
# pin

get '/open' => sub {
  my $c = shift;
  my $params = {};
  my $param_names = $c->req->params->names;
  for (@$param_names) {
      $params->{$_} = $c->param($_);
  }

  ### VALIDATION AND DETAILED ERROR LOGGING
  if (!exists $params->{telegram_username} && !exists $params->{telegram_id} && !exists $params->{card_id}) {
    app->log->debug('Not enough parameters provided: telegram_username or telegram_id or card_id');
    $c->render(json => { error => 'Not enough parameters provided: telegram_username or telegram_id or card_id' });
    return 1;
  }
  my @a =  qw/door_id pin/; # essential parameters
  my @absent_params;
  for (@a) {
    if (!$params->{$_}) {
      push @absent_params, $_;
    }
  }
  if (@absent_params) {
    $c->render(json => { error => 'Not enough parameters provided: '.join(', ',@absent_params) });
    return 1;
  }
  ### VALIDATION AND DETAILED ERROR LOGGING

  # server-side validation. leave only essential parameters for db query in %hash
  my %filtered_params = map { $_ => $params->{$_} } grep { exists $params->{$_} } qw/telegram_id card_id telegram_username/;

  # warn Dumper \%filtered_params;
  # warn 'All http params:'.Dumper $params;

  my $user = $db->search_user_in_db(%filtered_params);
  warn Dumper $user;

  if (%$user)  { # if user is found in database
    app->log->debug("User found in database!");
    # my $perm = $db->door_permissions_all($params->{door_id});
    # warn Dumper $perm;
    if ($db->is_door_restricted($params->{door_id})) { # door is restricted
      my $perm = $db->door_permissions_all($params->{door_id});
      warn "All door permissions: ".Dumper $perm;
      # warn Dumper $perm;
      # add code to check user-door permissions
      app->log->debug("Door is restricted for particular users. Code is not implemented yet");
      $c->render(json => { result => 'This user is not allowed to open this door'});
    } else {
      app->log->debug("This door (id=".$params->{door_id}.") has no permissions");
      if ($user->{pin} eq $params->{pin}) {
          my $log = $db->open_door($params->{door_id});
          $c->render(json => { result => $log });  # result from script output
      } else {
          $c->render(json => { result => 'Wrong password!'});
      }
    }
  } else {
    app->log->debug("User not found in database!");
    $c->render(json => { result => 'User not found in database'});
  }
};

app->start;
