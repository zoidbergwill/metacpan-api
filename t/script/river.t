use strict;
use warnings;

use lib 't/lib';

use Git::Helpers qw( checkout_root );
use MetaCPAN::Script::River;
use MetaCPAN::Script::Runner;
use MetaCPAN::Server::Test;
use MetaCPAN::TestHelpers;
use Test::More;
use URI;

my $config = MetaCPAN::Script::Runner::build_config;

# local json file with structure from https://github.com/CPAN-API/cpan-api/issues/460
my $root = checkout_root();
my $file = URI->new('t/var/river.json')->abs("file://$root/");
$config->{'river_url'} = "$file";

my $river = MetaCPAN::Script::River->new_with_options($config);
ok $river->run, 'runs and returns true';

my %expect = (
    'System-Command' => {
        total     => 92,
        immediate => 4,
        bucket    => 2,
    },
    'Text-Markdown' => {
        total     => 92,
        immediate => 56,
        bucket    => 2,
    }
);

test_psgi app, sub {
    my $cb = shift;
    for my $dist ( keys %expect ) {
        my $test = $expect{$dist};
        subtest "Check $dist" => sub {
            my $url = "/distribution/$dist";
            ok( my $res = $cb->( GET $url ), "GET $url" );

            # TRAVIS 5.18
            is( $res->code, 200, "code 200" );
            is(
                $res->header('content-type'),
                'application/json; charset=utf-8',
                'Content-type'
            );
            my $json = decode_json_ok($res);

            # TRAVIS 5.18
            is_deeply( $json->{river}, $test,
                "$dist river summary roundtrip" );
        };
    }
};

done_testing();
