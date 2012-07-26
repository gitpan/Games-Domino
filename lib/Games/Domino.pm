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

=head1 NAME

Games::Domino - Interface to the Domino game.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

has 'stock'     => (is => 'rw', isa => 'ArrayRef[Games::Domino::Tile]');
has 'board'     => (is => 'rw', isa => 'ArrayRef[Games::Domino::Tile]');
has 'human'     => (is => 'rw', isa => 'Games::Domino::Player');
has 'computer'  => (is => 'rw', isa => 'Games::Domino::Player');
has 'current'   => (is => 'rw', isa => 'Games::Domino::Player');
has 'open_ends' => (is => 'rw', isa => 'ArrayRef[ZeroToSix]');
has 'board_l'   => (is => 'rw', isa => 'ZeroToSix');
has 'board_r'   => (is => 'rw', isa => 'ZeroToSix');
has 'cheat'     => (is => 'ro', isa => 'ZeroOrOne', default => 0);
has 'debug'     => (is => 'rw', isa => 'ZeroOrOne', default => 0);

=head1 DESCRIPTION

This is a very basic Domino game played by two players  (computer vs computer) at the  moment.
I will extend it to make it interactive so that it can be played against human very soon. This
is just an initial draft of Proof of Concept. Also to get my head around the game which I have
never played in my life before.The two player in this games are named as "Human" & "Computer".
Although there is no human interference at this point in time but it will be in future.  There
is a cheat flag which makes the tiles for "Computer" visible to the other player "Human".Avoid
this flag if possible. By the default the cheat flag is turned off. There is a debug switch as
well which is turned off by default.They are arranged like here before we shuffle to start the
the game.

    [0 | 0]
    [0 | 1] [1 | 1]
    [0 | 2] [1 | 2] [2 | 2]
    [0 | 3] [1 | 3] [2 | 3] [3 | 3]
    [0 | 4] [1 | 4] [2 | 4] [3 | 4] [4 | 4]
    [0 | 5] [1 | 5] [2 | 5] [3 | 5] [4 | 5] [5 | 5]
    [0 | 6] [1 | 6] [2 | 6] [3 | 6] [4 | 6] [5 | 6] [6 | 6]

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();

=cut

sub BUILD
{
    my $self  = shift;

    $self->{stock} = $self->_prepare();
    $self->{human} = Games::Domino::Player->new({ name => 'H', show => 1 });
    if ($self->cheat)
    {
        $self->{computer} = Games::Domino::Player->new({ name => 'C', show => 1 });
    }
    else
    {
        $self->{computer} = Games::Domino::Player->new({ name => 'C' });
    }

    $self->{human}->save(shift @{$self->{stock}})    for (1..7);
    $self->{computer}->save(shift @{$self->{stock}}) for (1..7);
    $self->{current} = $self->{human};

    if ($self->debug)
    {
        print {*STDOUT} "H: " . $self->human    . "\n";
        print {*STDOUT} "C: " . $self->computer . "\n";
        print {*STDOUT} "\n\n";
    }
}

=head1 METHODS

=head2 draw()

Pick a tile from the  current  player. If  no matching tile found then picks it from the stock
until it found one or the stock has only 2 tiles left at that time the game is over.

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();
    my $tile = $game->draw();

=cut

sub draw
{
    my $self = shift;
    my $tile = $self->_next()->pick($self->open_ends);
    return $tile if defined $tile;

    while (scalar(@{$self->{stock}}) > 2)
    {
        $tile = $self->_pick();
        $self->{current}->save($tile);
        $tile = $self->{current}->pick($self->open_ends);
        return $tile if defined $tile;
    }
}

=head2 save()

Saves the given tile and arrange it properly on the board. Also capture the open ends for next
move.

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();
    my $tile = $game->draw();
    $game->save($tile);

=cut

sub save
{
    my $self = shift;
    my $tile = shift;

    if (!defined($self->{board}) || (scalar(@{$self->{board}}) == 0))
    {
        push @{$self->{board}}, $tile;
        $self->{board_l} = $tile->left;
        $self->{board_r} = $tile->right;
        $self->_open_ends([$self->{board_l}, $self->{board_r}]);
        $self->_next;
        return;
    }

    if ($self->{board_r} == $tile->left)
    {
        push @{$self->{board}}, $tile;
        $self->{board_r} = $tile->right;
        $self->_open_ends([$self->{board_l}, $self->{board_r}]);
        $self->_next;
        return;
    }
    elsif ($self->{board_r} == $tile->right)
    {
        my $L = $tile->left;
        my $R = $tile->right;
        $tile->right($L);
        $tile->left($R);
        push @{$self->{board}}, $tile;
        $self->{board_r} = $L;
        $self->_open_ends([$self->{board_l}, $self->{board_r}]);
        $self->_next;
        return;
    }

    if ($self->{board_l} == $tile->left)
    {
        my $L = $tile->left;
        my $R = $tile->right;
        $tile->right($L);
        $tile->left($R);
        unshift @{$self->{board}}, $tile;
        $self->{board_l} = $R;
        $self->_open_ends([$self->{board_l}, $self->{board_r}]);
        $self->_next;
        return;

    }
    elsif ($self->{board_l} == $tile->right)
    {
        unshift @{$self->{board}}, $tile;
        $self->{board_l} = $tile->left;
        $self->_open_ends([$self->{board_l}, $self->{board_r}]);
        $self->_next;
        return;
    }

    return;
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

    my $game = Games::Domino->new();
    do
    {
        my $tile = $game->draw();
        $game->save($tile) if defined $tile;
    } until ($game->is_over());

=cut

sub is_over
{
    my $self = shift;
    return 1 if ((scalar(@{$self->{stock}}) == 2)
                 ||
                 (scalar(@{$self->{human}->{bank}}) == 0)
                 ||
                 (scalar(@{$self->{computer}->{bank}}) == 0));
    return 0;
}

=head2 get_winner()

Declares who is the winner against whom and by how much margin.

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();
    do
    {
        my $tile = $game->draw();
        $game->save($tile) if defined $tile;
    } until ($game->is_over());

    print "WINNER: " . $game->get_winner() . "\n";

=cut

sub get_winner
{
    my $self = shift;
    my $h = $self->{human}->value();
    my $c = $self->{computer}->value();
    if ($h > $c)
    {
        return "C [$c] against H [$h]";
    }
    else
    {
        return "H [$h] against C [$c]";
    }
}

=head2 get_board()

Returns all the tiles that were arranged during the game.

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();
    do
    {
        my $tile = $game->draw();
        $game->save($tile) if defined $tile;
    } until ($game->is_over());

    print "BOARD :" . $game->get_board() . "\n";

=cut

sub get_board
{
    my $self = shift;

    my $board = '';
    foreach (@{$self->{board}})
    {
        $board .= sprintf("%s == ", $_);
    }
    $board =~ s/[\=]+\s?$//;
    $board =~ s/\s+$//;
    return $board;
}

=head2 as_string()

Returns all the unused tiles remained in the bank.

    use strict; use warnings;
    use Games::Domino;

    my $game = Games::Domino->new();
    do
    {
        my $tile = $game->draw();
        $game->save($tile) if defined $tile;
    } until ($game->is_over());

    print "STOCK : $game\n\n";

=cut

sub as_string
{
    my $self = shift;
    return '[EMPTY]' unless scalar(@{$self->{stock}});

    my $stock = '';
    foreach (@{$self->{stock}})
    {
        $stock .= sprintf("%s == ", $_);
    }
    $stock =~ s/[\=]+\s?$//;
    $stock =~ s/\s+$//;
    return $stock;
}

sub _pick
{
    my $self = shift;
    return shift @{$self->{stock}};
}

sub _prepare
{
    my $self  = shift;

    my $tiles = [];
    my $tile  = Games::Domino::Tile->new({ left => 0, right => 0, double => 1 });
    push @$tiles, $tile;
    foreach my $R (1..6)
    {
        my $L = 0;
        my $D = 0;
        while ($R >= $L)
        {
            ($R == $L)?($D = 1):($D = 0);
            push @$tiles, Games::Domino::Tile->new({ left => $L, right => $R, double => $D });
            $L++;
        }
    }

    $tiles = [shuffle @{$tiles}];
    return $tiles;
}

sub _open_ends
{
    my $self = shift;
    my $ends = shift;
    return if (defined($self->{open_ends}) && (scalar(@{$self->{open_ends}}) == 0));

    push @{$self->{open_ends}}, @{$ends};
}

sub _next
{
    my $self = shift;

    if ($self->{current}->name eq 'H')
    {
        $self->{current} = $self->{computer};
    }
    else
    {
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