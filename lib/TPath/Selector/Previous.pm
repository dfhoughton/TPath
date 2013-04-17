package TPath::Selector::Previous;

# ABSTRACT: C<TPath::Selector> that implements C<:p>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

# required by TPath::Selector
sub select {
    my ( $self, $ctx ) = @_;
    $ctx->previous;
}

sub to_string { return '/:p' }

__PACKAGE__->meta->make_immutable;

1;

