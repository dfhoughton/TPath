package TPath::TypeCheck;

# ABSTRACT: applies type constraint on nodes

=head1 DESCRIPTION

Role of an object that checks the class of a node against the class it knows it can handle.

=cut

use Moose::Role;

=head1 ATTRIBUTES

=over 8

=item node_type

If set on object construction, all nodes handled by the C<TPath::TypeCheck> will have 
to be of this class or an error will be thrown. Can be used to enforce type safety. 
The test is only performed on certain gateway methods -- C<TPath::Expression::select()> and 
C<TPath::Index::index()> -- so little overhead is incurred.

=back

=cut

has node_type =>
  ( isa => 'Maybe[Str]', is => 'ro', writer => '_node_type', default => undef );
  
=method _typecheck

Expects a node. Confesses if the node is of the wrong type.

=cut

sub _typecheck {
    my ( $self, $n ) = @_;
    return unless $self->node_type;
    confess 'can only handle nodes of type ' . $self->node_type
      unless $n->isa( $self->node_type );
}

1;
