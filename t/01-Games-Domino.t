#!perl

use strict; use warnings;
use Games::Domino;
use Test::More tests => 4;

my ($game, $tile);

$game = Games::Domino->new();
ok($game);

eval { Games::Domino->new({ cheat => 2 }); };
like($@, qr/Attribute \(cheat\) does not pass the type constraint/);

eval { Games::Domino->new({ debug => 2 }); };
like($@, qr/Attribute \(debug\) does not pass the type constraint/);

$tile = $game->draw();
ok($tile);