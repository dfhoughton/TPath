package TPath::TypeCheck;

# ABSTRACT : applies type constraint on nodes

use Moose::Role;

has node_type => ( isa => 'Str', is => 'ro' );

sub _typecheck {
    my ( $self, $n ) = @_;
    return unless $self->node_type;
    confess 'can only handle nodes of type ' . $self->node_type
      unless $n->isa( $self->node_type );
}

1;
