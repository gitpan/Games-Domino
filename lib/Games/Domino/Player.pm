package Games::Domino::Player;

use 5.006;
use strict; use warnings;

use Carp;
use Mouse;
use Mouse::Util::TypeConstraints;

use Data::Dumper;
use overload ( '""'  => \&as_string );

=head1 NAME

Games::Domino::Player - Represents the player of the Domino game.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

type 'HorC' => where { /^[H|C]$/i };

has 'name'  => (is => 'ro', isa => 'HorC', required => 1);
has 'bank'  => (is => 'rw', isa => 'ArrayRef[Games::Domino::Tile]');
has 'score' => (is => 'rw', isa => 'Int');
has 'show'  => (is => 'rw', isa => 'ZeroOrOne', default => 0);

=head1 DESCRIPTION

The Games::Domino::Player class is used by Games::Domino class internally.It shouldn't be used
directly.

=head1 METHODS

=head2 save()

Saves the given tile to the bank of the player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));

=cut

sub save
{
    my $self = shift;
    my $tile = shift;

    croak("ERROR: Undefined tile found.\n") unless defined $tile;

    push @{$self->{bank}}, $tile;
}

=head2 value()

Returns the total value of all the tiles of the current player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    print "The total value of the player is [" . $player->value . "]\n";

=cut

sub value
{
    my $self  = shift;
    $self->{score} = 0;
    foreach (@{$self->{bank}})
    {
        $self->{score} += $_->value;
    }
    return $self->{score};
}

=head2 as_string()

Returns the player object as string.This method is overloaded as string context.So if we print
the object then this method gets called. You can explictly call this method  as  well. Suppose
the player has 2 tiles then this return something like [1 | 4] == [5 | 3].

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    print "Player: $player\n";

=cut

sub as_string
{
    my $self = shift;
    my $bank = '';
    foreach (@{$self->{bank}})
    {
        if ($self->show)
        {
            $bank .= sprintf("[%d | %d] == ", $_->left, $_->right);
        }
        else
        {
            $bank .= sprintf("[x | x] == ");
        }
    }
    $bank =~ s/[\=]+\s?$//;
    $bank =~ s/\s+$//;
    return $bank;
}

=head2

Returns a matching tile for the given open ends. If no open ends found it then returns highest
value tile from the bank of the player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    my $tile = $player->pick();
    print "Tile: $tile\n";

=cut

sub pick
{
    my $self = shift;
    my $ends = shift;

    return $self->_pick($ends)
        if (defined($ends) && (scalar(@$ends) > 0));

    my $i    = 0;
    my $pos  = 0;
    my $max  = 0;
    my $tile = undef;

    foreach (@{$self->{bank}})
    {
        if ($_->value > $max)
        {
            $max  = $_->value;
            $tile = $_;
            $pos  = $i;
        }
        $i++;
    }

    splice(@{$self->{bank}}, $pos, 1);
    return $tile;
}

sub _pick
{
    my $self = shift;
    my $ends = shift;

    my $i    = 0;
    my $pos  = 0;
    my $tile = undef;
    foreach (@{$self->{bank}})
    {
        my $L = $_->left;
        my $R = $_->right;
        if (grep(/$L/, @{$ends}) || grep (/$R/, @{$ends}))
        {
            $pos = $i;
            $tile = $_;
            last;
        }
        $i++;
    }

    if (defined($tile))
    {
        splice(@{$self->{bank}}, $i, 1);
        return $tile;
    }
    return;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-domino at rt.cpan.org>,  or  through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Domino>. I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Domino::Player

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

1; # End of Games::Domino::Player