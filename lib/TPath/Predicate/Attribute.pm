package TPath::Predicate::Attribute;

# ABSTRACT: implements the [@foo] in //a/b[@foo]

=head1 DESCRIPTION

The object that selects the correct member of collection based whether they have a particular attribute.

=cut

use Moose;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr idx

The index of the item selected.

=cut

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

sub filter {
    my ( $self, $c, $i ) = @_;
    return grep { $self->a->test( $_, $c, $i ) } @$c;
}

__PACKAGE__->meta->make_immutable;

1;
