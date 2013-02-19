package TPath::Selector::Id;

# ABSTRACT: C<TPath::Selector> that implements C<id(foo)>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

has id => ( isa => 'Str', is => 'ro', required => 1 );

=method select

Expects a node and an index. Returns the node, if any, bearing this selector's id.

=cut

sub select {
    my ( $self, undef, $idx ) = @_;
    my $n = $idx->indexed->{ $self->id };
    $n // ();
}

__PACKAGE__->meta->make_immutable;

1;

