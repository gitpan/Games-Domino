#!perl

use strict; use warnings;
use Games::Domino;

my $game = Games::Domino->new({ debug => 1 });

do
{
    my $tile = $game->draw();
    $game->save($tile) if defined $tile;
} until ($game->is_over());

print "H: " . $game->human    . "\n";
print "C: " . $game->computer . "\n";
print "\n\n";

print "STOCK : $game\n\n";
print "BOARD : " . $game->get_board()  . "\n\n";
print "WINNER: " . $game->get_winner() . "\n\n";