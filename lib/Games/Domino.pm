package Games::Domino;

use 5.006;
use strict; use warnings;

use Carp;
use Mouse;
use Data::Dumper;
use List::Util qw(shuffle);
use Mouse::Util::TypeConstraints;
use overload ( '""'  => \&as_string );

use Games::Domino::Tile;
use Games::Domino::Player;

select(STDOUT);
$|=1;

$SIG{'INT'} = sub { print {*STDOUT} "\n\nCaught Interrupt (^C), Aborting the game.\n"; exit(1); };

=head1 NAME

Games::Domino - Interface to the Domino game.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

has 'stock'    => (is => 'rw', isa => 'ArrayRef[Games::Domino::Tile]');
has 'board'    => (is => 'rw', isa => 'ArrayRef[Games::Domino::Tile]');
has 'human'    => (is => 'rw', isa => 'Games::Domino::Player');
has 'computer' => (is => 'rw', isa => 'Games::Domino::Player');
has 'current'  => (is => 'rw', isa => 'Games::Domino::Player');
has 'board_l'  => (is => 'rw', isa => 'ZeroToSix');
has 'board_r'  => (is => 'rw', isa => 'ZeroToSix');
has 'cheat'    => (is => 'ro', isa => 'ZeroOrOne', default => 0);
has 'debug'    => (is => 'rw', isa => 'ZeroOrOne', default => 0);

=head1 DESCRIPTION

This is a very basic Domino game played by two players (Computer vs Human) at the  moment.This
is just an initial draft of Proof of Concept, also to get my head around the game which I have
never played in my life before. There is a cheat flag which makes tiles for "Computer" visible
to the other player "Human". Avoid this flag if possible. By default  the cheat flag is turned
off.There is a debug switch as well which is turned off by default.They are arranged like here
before we shuffle to start the the game.

    [0 | 0]
    [0 | 1] [1 | 1]
    [0 | 2] [1 | 2] [2 | 2]
    [0 | 3] [1 | 3] [2 | 3] [3 | 3]
    [0 | 4] [1 | 4] [2 | 4] [3 | 4] [4 | 4]
    [0 | 5] [1 | 5] [2 | 5] [3 | 5] [4 | 5] [5 | 5]
    [0 | 6] [1 | 6] [2 | 6] [3 | 6] [4 | 6] [5 | 6] [6 | 6]

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();

=cut

sub BUILD
{
    my $self  = shift;

    $self->{stock} = $self->_prepare();
    $self->{human} = Games::Domino::Player->new({ name => 'H', show => 1 });

    if ($self->cheat) {
        $self->{computer} = Games::Domino::Player->new({ name => 'C', show => 1 });
    } else {
        $self->{computer} = Games::Domino::Player->new({ name => 'C' });
    }

    $self->{human}->save(shift @{$self->{stock}})    for (1..7);
    $self->{computer}->save(shift @{$self->{stock}}) for (1..7);
    $self->{current} = $self->{computer};

    $self->_instructions;
    $self->show if $self->debug;
}

=head1 METHODS

=head2 play()

Pick a tile from the  current  player. If  no matching tile found then picks it from the stock
until it found one or the stock has only 2 tiles left at that time the game is over.

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();
    $domino->play;

=cut

sub play {
    my $self = shift;

    my $player = $self->{current};
    if ($player->name eq 'C') {
        my $tile = $player->pick($self->board_l, $self->board_r);
        if (defined $tile) {
            print {*STDOUT} "[C] [P]: $tile [S]\n" if $self->debug;
            $self->_save($tile);
            return $tile;
        }

        $tile = $self->_play($player->name);
        return $tile if defined $tile;

    } else {
        my $index;
        do {
            print {*STDOUT} "Pick your tile [" . $player->_available_indexes . "][B]? ";
            $index = <STDIN>;
            chomp($index) if defined $index;

            if (defined($index) && ($index =~ /B/i)) {
                my $tile = $self->_play($player->name);
                return $tile if defined $tile;
            }
        } until (defined($index) && $player->_validate_index($index) && $player->_validate_tile($index, $self->board_l, $self->board_r));

        my $tile = $player->_tile($index);
        print {*STDOUT} "[H] [P]: $tile [S]\n" if $self->debug;
        splice(@{$player->{bank}}, $index-1, 1);
        $self->_save($tile);
        return $tile;
    }
}

=head2 is_over()

Returns 1 or 0 depending whether the game is over or not. The game can be declared over in the
following circumstances:

=over 2

=item * Any one of the two players have used all his tiles.

=item * There are only two (2) tiles left in the bank.

=back

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();
    do { $domino->play; } until $domino->is_over;

=cut

sub is_over {
    my $self = shift;
    return 1 if ((scalar(@{$self->{stock}}) == 2)
                 ||
                 (scalar(@{$self->{human}->{bank}}) == 0)
                 ||
                 (scalar(@{$self->{computer}->{bank}}) == 0));
    return 0;
}

=head2 result()

Declares who is the winner against whom and by how much margin.

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();
    do { $domino->play; } until $domino->is_over;
    $domino->result;

=cut

sub result {
    my $self = shift;

    print {*STDOUT} "STOCK : $self\n";
    my $h = $self->{human}->value();
    my $c = $self->{computer}->value();
    if ($h == $c) {
        if (scalar(@{$self->{computer}->{bank}}) < scalar(@{$self->{human}->{bank}})) {
            print {*STDOUT} "WINNER: [C] [$c] against [H] [$h]\n";
        } else {
            print {*STDOUT} "WINNER: [H] [$h] against [C] [$c]\n";
        }
    } elsif ($h > $c) {
        print {*STDOUT} "WINNER: [C] [$c] against [H] [$h]\n";
    } else {
        print {*STDOUT} "WINNER: [H] [$h] against [C] [$c]\n";
    }
    $self->_line;
}

=head2 show()

Print the current tiles of Computer, Human and matched one.

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();
    do { $domino->play; $domino->show; } until $domino->is_over;

=cut

sub show {
    my $self = shift;
    $self->_line;
    print {*STDOUT} "[C]: " . $self->computer . "\n";
    print {*STDOUT} "[H]: " . $self->human    . "\n";
    print {*STDOUT} "[G]: " . $self->_board() . "\n";
    $self->_line;
}

=head2 as_string()

Returns all the unused tiles remained in the bank.

    use strict; use warnings;
    use Games::Domino;

    my $domino = Games::Domino->new();
    do { $domino->play; } until $domino->is_over;
    print "DOMINO : $domino\n\n";

=cut

sub as_string {
    my $self = shift;
    return '[EMPTY]' unless scalar(@{$self->{stock}});

    my $domino = '';
    foreach (@{$self->{stock}}) {
        $domino .= sprintf("%s==", $_);
    }
    $domino =~ s/[\=]+\s?$//;
    $domino =~ s/\s+$//;
    return $domino;
}

sub _instructions {
    my $self = shift;
    my $help = qq {
   _____                               _____                  _
  / ____|                          _ _|  __ \\                (_)
 | |  __  __ _ _ __ ___   ___  ___(_|_) |  | | ___  _ __ ___  _ _ __   ___
 | | |_ |/ _` | '_ ` _ \\ / _ \\/ __|   | |  | |/ _ \\| '_ ` _ \\| | '_ \\ / _ \\
 | |__| | (_| | | | | | |  __/\\__ \\_ _| |__| | (_) | | | | | | | | | | (_) \|
  \\_____|\\__,_|_| |_| |_|\\___||___(_|_)_____/ \\___/|_| |_| |_|_|_| |_|\\___/

Tiles are numbered left to right starting with 1. Symbols used in this game are:
    [C]: Code for the computer player
    [H]: Code for the human player
    [P]: Personal tile
    [B]: Tile picked from the bank
    [S]: Successfully found the matching tile
    [F]: Unable to find the matching tile
    [G]: All matched tiles so far

Example:

[C] [P]: [5 | 6] [S]
Computer picked the tile [5 | 6] from his own collection and successfully found the matching on board.

[H] [P]: [6 | 6] [S]
Human picked the tile [6 | 6] from his own collection and successfully found the matching on board.

[C] [B]: [2 | 6] [S]
Computer randomly picked the tile [2 | 6] from the bank and successfully found the matching on board.

[C] [B]: [3 | 4] [F]
Computer randomly picked the tile [3 | 4] from the bank and but failed to find the matching on board.

[H] [B]: [2 | 2] [S]
Human randomly picked the tile [2 | 2] from the bank and successfully found the matching on board.

[H] [B]: [3 | 6] [F]
Human randomly picked the tile [3 | 6] from the bank and but failed to find the matching on board.
};
    $self->_line;
    print {*STDOUT} $help,"\n";
    $self->_line;
}

sub _play {
    my $self   = shift;
    my $player = $self->{current};
    my $name   = $player->name;
    while (scalar(@{$self->{stock}}) > 2) {
        my $_tile = $self->_pick();
        $player->save($_tile);
        my $tile = $player->pick($self->board_l, $self->board_r);
        if (defined $tile) {
            print {*STDOUT} "[$name] [B]: $tile [S]\n" if $self->debug;
            $self->_save($tile);
            return $tile;
        } else {
            print {*STDOUT} "[$name] [B]: $_tile [F]\n" if $self->debug;
        }
    }
}

sub _save {
    my $self = shift;
    my $tile = shift;

    if (!defined($self->{board}) || (scalar(@{$self->{board}}) == 0)) {
        push @{$self->{board}}, $tile;
        $self->{board_l} = $tile->left;
        $self->{board_r} = $tile->right;
        $self->_next;
        return;
    }

    if ($self->{board_r} == $tile->left) {
        push @{$self->{board}}, $tile;
        $self->{board_r} = $tile->right;
        $self->_next;
        return;

    } elsif ($self->{board_r} == $tile->right) {
        my $L = $tile->left;
        my $R = $tile->right;
        $tile->right($L);
        $tile->left($R);
        push @{$self->{board}}, $tile;
        $self->{board_r} = $L;
        $self->_next;
        return;
    }

    if ($self->{board_l} == $tile->left) {
        my $L = $tile->left;
        my $R = $tile->right;
        $tile->right($L);
        $tile->left($R);
        unshift @{$self->{board}}, $tile;
        $self->{board_l} = $R;
        $self->_next;
        return;

    } elsif ($self->{board_l} == $tile->right) {
        unshift @{$self->{board}}, $tile;
        $self->{board_l} = $tile->left;
        $self->_next;
        return;
    }

    return;
}

sub _board {
    my $self = shift;

    my $board = '';
    foreach (@{$self->{board}}) {
        $board .= sprintf("%s==", $_);
    }
    $board =~ s/[\=]+\s?$//;
    $board =~ s/\s+$//;
    return $board;
}

sub _line {
    my $self = shift;
    print {*STDOUT} "="x76,"\n";
}

sub _pick {
    my $self = shift;
    return shift @{$self->{stock}};
}

sub _prepare {
    my $self  = shift;

    my $tiles = [];
    my $tile  = Games::Domino::Tile->new({ left => 0, right => 0, double => 1 });
    push @$tiles, $tile;
    foreach my $R (1..6) {
        my $L = 0;
        my $D = 0;
        while ($R >= $L) {
            ($R == $L)?($D = 1):($D = 0);
            push @$tiles, Games::Domino::Tile->new({ left => $L, right => $R, double => $D });
            $L++;
        }
    }

    $tiles = [shuffle @{$tiles}];
    return $tiles;
}

sub _next {
    my $self = shift;

    if ($self->{current}->name eq 'H') {
        $self->{current} = $self->{computer};
    } else {
        $self->{current} = $self->{human};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-domino at rt.cpan.org>, or  through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Domino>.I will be
notified,and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Domino

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Domino>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Domino>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Domino>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Domino/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;
no Mouse::Util::TypeConstraints;

1; # End of Games::Domino