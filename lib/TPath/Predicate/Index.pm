package TPath::Predicate::Index;

# ABSTRACT : implements the [0] in //a/b[0]

=head1 DESCRIPTION

The object that selects the correct member of collection based on its index.

=cut

use Moose;
use TPath::Predicate;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr idx

The index of the item selected.

=cut

has idx => ( is => 'ro', isa => 'Int', required => 1 );

sub filter {
    my ( $self, $c, $i ) = @_;
    return $c->[ $self->idx ];
}

__PACKAGE__->meta->make_immutable;

1;
