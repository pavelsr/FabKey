
use WWW::Telegram::BotAPI;
use Mojolicious::Lite;
use Telegram::BotKit::Keyboards qw(create_one_time_keyboard create_inline_keyboard);
use Telegram::BotKit::Polling qw(get_last_messages);
use Data::Dumper; # for debug

use Date::Format;
use Telegram::Bot::Message;
# test of https://core.telegram.org/bots/api#replykeyboardmarkup


my $token = '441592632:AAEACcNg6CXM_As4-zg4m68WrChis547iuo';

my $api = WWW::Telegram::BotAPI->new (
    token => $token
);

my %InlineKeyboardMarkup = (
    inline_keyboard => [
    	[
    		{ "text" => "Button_1", "callback_data" => "data1" }, # callback_data can be only string
    		{ "text" => "Button_2", "callback_data" => "data2" }
    	]
    ],
);


Mojo::IOLoop->recurring(1 => sub {
	my $hash = get_last_messages($api);
	while ( my ($chat_id, $update) = each(%$hash) ) {   # Answer to all connected clients
  	app->log->info("Update object:".Dumper $update);

    my $mo = Telegram::Bot::Message->create_from_hash($update->{message});
    my $dth =  time2str("%R %a %o %b %Y", $mo->date);
    warn "Update time: ".$mo->date.", human: ".$dth;
    my $curr = time();
    warn "Current time: ".$curr;
    warn "Difference, sec: ".($curr-($mo->date));

    if ($update->{message}{text} eq '/kb') {
      $api->sendMessage({
          chat_id => $update->{message}{chat}{id},
          text => 'Example inline keyboard',
          #reply_markup => create_inline_keyboard(['Button1','Button2'], 2)
          reply_markup => JSON::MaybeXS::encode_json(\%InlineKeyboardMarkup)
        });
    }
  }
  # app->log->info($update->{message}{text}." from chat_id: ".$chat_id." (".$update->{message}{from}{first_name}." ".$update->{message}{from}{last_name}.")");
});

app->start;


# Reply fields
# https://bitbucket.org/serikov/tg_dt_picker/src/0d8a0fc59e718badf17371505b77f98fecd4e20f/README.md?at=master&fileviewer=file-view-default
