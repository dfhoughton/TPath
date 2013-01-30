package TPath::IdSelector;

# ABSTRACT : C<TPath::Selector> that implements C<id(foo)>

use Moose;
use TPath::Selector;
use namespace::autoclean;

with 'TPath::Selector';

has id => ( isa => 'Str', is => 'ro', required => 1 );

=method select

Expects a node and an index. Returns the node, if any, bearing this selector's id.

=cut

sub select {
    my ( $self, undef, $idx ) = @_;
    my $n = $idx->identified->{ $self->id };
    $n // ();
}

__PACKAGE__->meta->make_immutable;

1;

