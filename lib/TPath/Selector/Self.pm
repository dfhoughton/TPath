package TPath::Selector::Self;

# ABSTRACT: L<TPath::Selector> that implements C<.>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

# required by TPath::Selector
sub select {
    my ( $self, $n, $idx ) = @_;
    $n;
}

__PACKAGE__->meta->make_immutable;

1;

