#!perl

use strict; use warnings;
use Games::Domino::Tile;
use Test::More tests => 10;

my ($tile);

$tile = Games::Domino::Tile->new({ left => 1, right => 5 });
ok($tile);

is($tile->value, 6);
is($tile->as_string, "[1 | 5]");

eval { Games::Domino::Tile->new({ left => 1 }) };
like($@, qr/Attribute \(right\) is required/);

eval { Games::Domino::Tile->new({ right => 1 }) };
like($@, qr/Attribute \(left\) is required/);

eval { Games::Domino::Tile->new({ left => 1, right => 7 }); };
like($@, qr/Attribute \(right\) does not pass the type constraint/);

eval { Games::Domino::Tile->new({ left => 7, right => 1 }); };
like($@, qr/Attribute \(left\) does not pass the type constraint/);

eval { Games::Domino::Tile->new({ left => 1, right => 1, double => 0 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);

eval { Games::Domino::Tile->new({ left => 1, right => 0, double => 2 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);

eval { Games::Domino::Tile->new({ left => 1, right => 0, double => 1 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);