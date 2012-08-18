package Games::Domino::Tile;

use 5.006;
use strict; use warnings;

use Carp;
use Mouse;
use Mouse::Util::TypeConstraints;
use overload ( '""'  => \&as_string );

=head1 NAME

Games::Domino::Tile - Represents the tile of the Domino game.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

type 'ZeroOrOne' => where { /^[1|0]$/ };
type 'ZeroToSix' => where { /^[0-6]$/ };

has 'left'   => (is => 'rw', isa => 'ZeroToSix', required => 1);
has 'right'  => (is => 'rw', isa => 'ZeroToSix', required => 1);
has 'top'    => (is => 'rw', isa => 'ZeroToSix', required => 0);
has 'bottom' => (is => 'rw', isa => 'ZeroToSix', required => 0);
has 'double' => (is => 'ro', isa => 'ZeroOrOne', required => 1);

=head1 DESCRIPTION

The Games::Domino::Tile class is used by Games::Domino class internally. It  shouldn't be used
directly.

=cut

around BUILDARGS => sub
{
    my $orig  = shift;
    my $class = shift;

    unless (exists $_[0]->{double})
    {
        if (defined($_[0]->{left}) && defined($_[0]->{right}) && ($_[0]->{left} == $_[0]->{right}))
        {
            $_[0]->{double} = 1;
            $_[0]->{top} = $_[0]->{bottom} = $_[0]->{left};
        }
        else
        {
            $_[0]->{double} = 0;
        }
    }

    croak("ERROR: Invalid double attribute for the tile.\n")
        if (defined($_[0]->{left})
            &&
            defined($_[0]->{right})
            &&
            ( (($_[0]->{left} == $_[0]->{right})
               &&
               ($_[0]->{double} != 1))
              ||
              (($_[0]->{left} != $_[0]->{right})
               &&
               ($_[0]->{double} != 0)) )) ;

    if ($_[0]->{double} == 1)
    {
        $_[0]->{top} = $_[0]->{bottom} = $_[0]->{left};
    }

    return $class->$orig(@_);
};

=head1 METHODS

=head2 value()

Returns the value of the tile i.e. sum of left and right bips.

    use strict; use warnings;
    use Games::Domino::Tile;

    my $tile = Games::Domino::Tile->new({ left => 1, right => 4 });
    print "Value of the tile is [" . $tile->value . "].\n";

=cut

sub value
{
    my $self = shift;
    return ($self->{left} + $self->{right});
}

=head2 as_string()

Returns the tile object as string. This method is overloaded as string context. So if we print
the object then this method gets called. You can explictly call this method  as  well. Suppose
the tile has 3 left pips and 6 right pips then this would return it as [3 | 6].

    use strict; use warnings;
    use Games::Domino::Tile;

    my $tile = Games::Domino::Tile->new({ left => 1, right => 4 });
    print "The tile is $tile\n";
    # same as above
    print "The tile is " . $tile->as_string() . "\n";

=cut

sub as_string
{
    my $self = shift;
    return sprintf("[%d | %d]", $self->left, $self->right);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-domino at rt.cpan.org>,  or  through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Domino>. I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Domino::Tile

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

1; # End of Games::Domino::Tile