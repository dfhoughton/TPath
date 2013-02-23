# ABSTRACT: general purpose path languages for trees

package TPath::Index;

=head1 SYNOPSIS

  my $f = MyForester->new;      # hypothetical forester for my sort of tree
  my $root = next_tree();       # generate my sort of tree
  my $index = $f->index($root); # construct reusable index for $root

=head1 DESCRIPTION

A cache of information about a particular tree. Reuse indices to save effort.

=cut

use Moose;
use MooseX::Privacy;
use Scalar::Util qw(refaddr weaken);
use namespace::autoclean;

use TPath::TypeConstraints;

with 'TPath::TypeCheck';

=attribute f

The L<TPath::Forester> that generated this index.

=cut

has f => ( is => 'ro', does => 'TPath::Forester', required => 1 );

has indexed => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _is_indexed => ( is => 'rw', isa => 'Bool', default => 0 );

=attribute cp_index

Map from children to their parents. This should be regarded as private.

=cut

has cp_index => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

has root => ( is => 'ro', required => 1 );

# micro-optimization
has _root_ref => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { refaddr $_[0]->root }
);

=method is_root

Expects a node. Returns whether this node is the root of the tree
indexed by this index.

=cut

sub is_root {
    my ( $self, $n ) = @_;
    return refaddr $n eq $self->_root_ref;
}

sub BUILD {
    my $self = shift;
    confess 'forester node type is '
      . $self->f->node_type
      . ' while index node type is '
      . $self->node_type
      unless $self->f->node_type eq $self->node_type;
    $self->walk( $self->root );
}

=method index

Cause this index to walk its tree and perform all necessary indexation.

=cut

sub index {
    my $self = shift;
    return if $self->_is_indexed;
    $self->walk( $self->root );
    $self->_is_indexed(1);
}

protected_method walk => sub {
    my ( $self, $n ) = @_;
    my @children = $self->f->_kids( $n, $self );
    $self->n_index($n);
    for my $c (@children) {
        $self->pc_index( $n, $c );
        $self->walk($c);
    }
};

=method parent

Expects a node and returns the parent of this node.

=cut

sub parent {
    my ( $self, $n ) = @_;
    return $self->cp_index->{ refaddr $n};
}

protected_method n_index => sub {
    my ( $self, $n ) = @_;
    my $id = $self->id($n);
    if ( defined $id ) {
        $self->indexed->{$id} = $n;
    }
};

=method pc_index

Record the link from child to parent. If this index is unnecessary for a
particular variety of tree -- nodes know their parents -- then you should
override this method to be a no-op. It is protected. It assumes all nodes
are references and will throw an error if this is not the case.

=cut

protected_method pc_index => sub {
    my ( $self, $n, $c ) = @_;
    confess "$c must be a reference" unless ref $c;
    my $ref = $n;
    weaken $ref;
    $self->cp_index->{ refaddr $c} = $ref;
};

=method id

Returns the unique identifier, if any, that identifies this node. This method
should be overridden in indexes that have some defined id convention. By default
it returns C<undef>.

=cut

sub id {
    my ( $self, $n ) = @_;
    $self->_typecheck($n);
    return $self->f->id($n);
}

__PACKAGE__->meta->make_immutable;

1;
