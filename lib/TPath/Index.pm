# ABSTRACT: general purpose path languages for trees

package TPath::Index;

use Moose;
use MooseX::Privacy;
use namespace::autoclean;

with 'TPath::TypeCheck';

has f => ( is => 'ro', isa => 'TPath::Forester', required => 1, );

has indexed => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => ['Private']
);

has root => ( is => 'ro', required => 1, );

=method is_root

Expects a node. Returns whether this node is the root of the tree
indexed by this index.

=cut

sub is_root {
    my ( $self, $n ) = @_;
    $self->_typecheck($n);
    return $n == $self->root;
}

sub BUILD {
    my $self = shift;
    confess 'forester node type is '
      . $self->f->node_type
      . ' while index node type is '
      . $self->node_type
      unless $self->f->node_type eq $self->node_type;
    $self->_walk( $self->root );
}

protected_method walk => sub {
    my ( $self, $n ) = @_;
    my @children = $self->f->kids( $n, $self );
    $self->index($n);
    for my $c (@children) {
        $self->pc_index( $n, $c );
        $self->walk($c);
    }
};

protected_method index => sub {
    my ( $self, $n ) = @_;
    my $id = $self->id($n);
    if ( defined $id ) {
        $self->identified->{$id} = $n;
    }
};

protected_method pc_index => sub {
    my ( $self, $n, $c ) = @_;
};

=method id

Returns the unique identifier, if any, that identifies this node. This method
should be overridden in indexes that have some defined id convention. By default
it returns C<undef>.

=cut

sub id {
    my ( $self, $n ) = @_;
    $self->_typecheck($n);
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
