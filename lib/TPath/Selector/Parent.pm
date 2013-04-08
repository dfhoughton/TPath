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
    my ( $self, $n, $i ) = @_;
    return $n == $i->root ? () : $i->f->parent( $n, $i );
}
sub to_string { '..' }

__PACKAGE__->meta->make_immutable;

1;

