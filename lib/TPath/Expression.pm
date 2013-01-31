package TPath::Expression;

# ABSTRACT : a compiled TPath expression

=head1 SYNOPSIS

  my $f     = MyForester->new;             # make a new forester for my sort of tree
  my $path  = $f->path('//foo[@bar][-1]'); # select the last foo with the bar property
  my $tree  = next_tree();                 # get the next tree (hypothetical function)
  my ($foo) = $path->select($tree);        # get the desired node
  $foo      = $path->first($tree);         # achieves the same result

=head1 DESCRIPTION

An object that will get us the nodes identified by our path expression.

=cut

use TPath::TypeCheck;
use Moose;
use namespace::autoclean;

has f => ( is => 'ro', isa => 'TPath::Forester', required => 1 );

has selectors =>
  ( is => 'ro', isa => 'ArrayRef[ArrayRef[TPath::Selector]]', required => 1 );

=method first

Convenience method that returns the first node selected by this expression from
the given tree. This method just delegates to C<select>.

=cut

sub first {
    my ( $self, $n, $i ) = @_;
    my @c = $self->select( $n, $i );
	return shift @c;
}

=method select

Takes a tree and, optionally, an index and returns the nodes selected from this
tree by the path. If you are doing many selections on a particular tree, you may
save some work by using a common index for all selections.

=cut

sub select {
    my ( $self, $n, $i ) = @_;
    confess 'select called on a null node' unless defined $n;
    $self->f->_type_check($n);
    $i //= $self->f->index($n);
    $i->index;
    my @sel;
    for my $fork ( @{ $self->selectors } ) {
        push @sel, _sel( $n, $i, $fork, 0 );
    }
    return @sel;
}

sub _sel {
    my ( $n, $i, $fork, $idx ) = @_;
    my @c = $fork->[ $idx++ ]->select( $n, $i );
    return @c if $idx == @$fork;
    my @sel;
    push @sel, _sel( $_, $i, $fork, $idx ) for @c;
    return @sel;
}

__PACKAGE__->meta->make_immutable;

1;
