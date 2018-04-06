use Mojolicious::Lite;
use Mojo::SQLite;
use Yancy;

plugin Yancy => {
    backend => $ARGV[0] || 'sqlite:skud.db',
    read_schema => 1,
    collections => {
        doors => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        },
        entries => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        },
        log => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        },
        permissions => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        },
        telegram_admission_requests => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        },
        users => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                }
            }
        }
    }
};

print "Running Yancy on $ARGV[0] database";

app->start;
