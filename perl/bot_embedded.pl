#!/usr/bin/env perl

## Telegram bot with support of FabKey API and FSM for entering pincode
## Version with EMBEDDED server (if you can't use VPN)
# Some code was taken from https://bitbucket.org/serikov/tg_dt_picker/
# and from https://metacpan.org/release/Telegram-BotKit

use WWW::Telegram::BotAPI;
use Telegram::Bot::Message;
use Telegram::BotKit::Sessions;
use Telegram::BotKit::Keyboards qw(create_one_time_keyboard);
use JSON::MaybeXS;
use Mojolicious::Lite;
use lib '.';
use DBUtil;
use Data::Dumper;

my $config = plugin JSONConfig => {file => 'config.json'};

my $telegram_token = $ENV{FABKEY_BOT_TOKEN} || $config->{FABKEY_BOT_TOKEN};
my $bot_name = '';
my $api;
my $polling_timeout = 1; # default
my $db = DBUtil->new(dbi => $config->{"DBI"});
app->log->debug("Using database: ".$config->{"DBI"});
my $sessions = Telegram::BotKit::Sessions->new();

helper check_for_updates => sub {
        my $c = shift;
        my $res = $api->deleteWebhook() ; # disable webhooks
        # warn Dumper $res;
        my $updates = $api->getUpdates();
        my $h = {
                updates_in_queue => {}
        };
        $h->{updates_in_queue}{count} = scalar @{$updates->{result}};
        $h->{updates_in_queue}{details} = \@{$updates->{result}};

        my @u_ids;
        for (@{$updates->{result}}) {
                push @u_ids, $_->{update_id};
        }

        $h->{updates_in_queue}{update_ids} = \@u_ids;

        #$c->setWebhook() if !($polling_flag); # set Webhook again if needed

        return $h;
};

my $door_info;

helper answer => sub {
	my ($c, $update) = @_;
	app->log->info("Processing new update...");
	my $mo = Telegram::Bot::Message->create_from_hash($update->{message});
	my $msg = $mo->text;
  my $from_id = $mo->from->id;
  my $chat_id = $mo->chat->id;
  my $date = $mo->date;  ## Check that message from latest 1 minute

  $sessions->start($chat_id) if (!defined $sessions->all($chat_id));
  #$sessions->update($chat_id, $msg);

  my $fabkey_user = $db->search_user_in_db(telegram_id => $from_id);

  ## FSM
  # https://metacpan.org/pod/FSA::Rules
  ## Need to create FSM (like active session) for each user
  # now bot correctly working only if one user working with it

  if ( ($msg eq "/open") || ($msg eq '/open@'.$bot_name )) {
    my $all_doors = $db->available_doors();  # you can provide $user_id
    my @keys_for_keyboard;
    for (values %$all_doors) {
      push @keys_for_keyboard, $_->{name};
    }

    #   push @keys_for_keyboard, { "text" => $_->{name}, "callback_data" => $_->{id} }  # pass door_id. Search by door name much complicated
    # }
    # my %InlineKeyboardMarkup = ( inline_keyboard => [ \@keys_for_keyboard ] ); # button text = door name, all in one row
    $api->sendMessage({
				chat_id => $chat_id,
				text => 'Please select a door',
				#reply_markup => JSON::MaybeXS::encode_json(\%InlineKeyboardMarkup)
        reply_markup => create_one_time_keyboard(\@keys_for_keyboard)
			});
    $sessions->update($chat_id, 1); # 1 - id of screen
  } elsif ($sessions->last($chat_id) eq 1) {   # replykeyboard markup hangles
    # get door id by name
    # $door_id = $db->get_door_id_by_name($msg);
    $door_info = $db->get_door_info_by_name($msg);
    warn "Door info: ".Dumper $door_info;
    $api->sendMessage({
				chat_id => $chat_id,
				text => 'Please input your password (4 digits)',
			});
    $sessions->update($chat_id, 2); # 1 - id of screen
  } elsif ($sessions->last($chat_id) eq 2) { # password handler

    my $rp = {
      telegram_id => $from_id,
      door_id => $door_info->{id},
      pin => $msg
    };

    warn "Req prms: ".Dumper $rp;

    # my $res = $c->ua->get( $config->{"MAIN_SRV_URL"} => form => $rp )->res->json;

    my $res = $db->authorize_user($rp);

    warn "Result of server API call: ".Dumper $res;

    #if ($res eq 'Door with gpio_pin='.$door_info->{gpio_pin}.' is opened!') {  # msg from echo of open_gpio.sh

    if ($res eq '1') {  # msg from echo of open_gpio.sh
      $api->sendMessage({ chat_id => $chat_id, text => 'Welcome to cmit!' });
      $sessions->del($chat_id);
      my $door_info = {};
    } else {
      $api->sendMessage({
  				chat_id => $chat_id,
  				text => 'Some problems occured. Try to start a new session: /open',
  			});
    }
    # $sessions->del($chat_id);
  } else {
    $api->sendMessage({
        chat_id => $chat_id,
        text => 'Command not recognized. Try to start a new session: /open',
      });
  }
  # $sessions->del($chat_id);
};


if ($telegram_token) { # maybe add
  $api = WWW::Telegram::BotAPI->new (
      token => $telegram_token
  );
  $bot_name = $api->getMe->{result}{username};
  my $queue = app->check_for_updates()->{updates_in_queue};
  app->log->info('Starting bot @'.$bot_name."...");
  app->log->info("Having ".$queue->{count}." stored Updates at Telegram server");
  app->log->info("Unprocessed update ids (for offset debug): ".join(',', @{$queue->{update_ids}}) );
  my $res = $api->deleteWebhook();
  app->log->info("For any case webhook was deleted. Starting polling with ".$polling_timeout."secs timeout ...") if $res;

  Mojo::IOLoop->recurring($polling_timeout => sub {
		my @updates = @{$api->getUpdates->{result}};
		if (@updates) {
			for my $u (@updates) {
        app->answer($u); # Mojolicious::Lite ->  Mojolicious::Controller -> Mojolicious::Helper
        $api->getUpdates({ offset => $u->{update_id} + 1.0 }); # clear buffer
			}
		}
	});
} else {
  die "Attention! Telegram API token isn't specified. Please edit config.json or set FABKEY_BOT_TOKEN env";
}





app->start;
