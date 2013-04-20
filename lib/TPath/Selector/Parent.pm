package TPath::Selector::Parent;

# ABSTRACT: L<TPath::Selector> that implements C<..>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

# required by TPath::Selector
sub select {
    my ( $self, $ctx ) = @_;
    my ( $n, $i ) = ( $ctx->n, $ctx->i );
    return $n == $i->root ? () : $i->f->parent( $ctx, $ctx );
}
sub to_string { '..' }

__PACKAGE__->meta->make_immutable;

1;

