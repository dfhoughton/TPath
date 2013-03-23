package TPath::Expression;

# ABSTRACT: a compiled TPath expression

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
use TPath::TypeConstraints;
use Scalar::Util qw(refaddr);
use Moose;
use namespace::autoclean;

sub uniq(@);

=head1 ROLES

L<TPath::Test>

=cut

with 'TPath::Test';

=attr f

The expression's L<TPath::Forester>.

=cut

has f => ( is => 'ro', does => 'TPath::Forester', required => 1 );

has _selectors =>
  ( is => 'ro', isa => 'ArrayRef[ArrayRef[TPath::Selector]]', required => 1 );

=method select( $n, [$i], [%opts] )

Takes a tree and, optionally, an index and options. Returns the nodes selected 
from this tree by the path if you want a list or the first node selected if you want a
scalar. 

The options, if any, will be passed through to the forester's C<wrap> method to
define any coercion necessary.

If you are doing many selections on a particular tree, you may save some work by 
using a common index for all selections.

=cut

sub select {
	my ( $self, $n, $i, %opts ) = @_;
	confess 'select called on a null node' unless defined $n;
	$n = $self->f->wrap( $n, %opts );
	$self->f->_typecheck($n);
	$i //= $self->f->index($n);
	$i->index;
	my $sel = $self->_select( $n, $i, 1 );
	return wantarray ? @$sel : $sel->[0];
}

# select minus the initialization steps
sub _select {
	my ( $self, $n, $i, $first ) = @_;

	my @sel;
	for my $fork ( @{ $self->_selectors } ) {
		push @sel, _sel( $n, $i, $fork, 0, $first );
	}
	@sel = uniq @sel if @{ $self->_selectors } > 1;

	return \@sel;
}

# required by TPath::Test
sub test {
	my ( $self, $n, $i ) = @_;
	!!$self->select( $n, $i );
}

# goes down steps of path
sub _sel {
	my ( $n, $i, $fork, $idx, $first ) = @_;
	my $selector = $fork->[ $idx++ ];
	my @c = uniq $selector->select( $n, $i, $first );
	return @c if $idx == @$fork;

	my ( $naddr, @sel );
	for my $context (@c) {
		my $still_first = $first && do {
			$naddr //= refaddr $n;
			$naddr eq refaddr $context && !$selector->consumes_first;
		};
		push @sel, _sel( $context, $i, $fork, $idx, $still_first );
	}
	return @sel;
}

# a substitute for List::MoreUtils::uniq which uses reference address rather than stringification to establish identity
sub uniq(@) {
	my %seen = ();
	return @_ if @_ == 1;
	grep { not $seen{ refaddr $_ }++ } @_;
}

__PACKAGE__->meta->make_immutable;

1;

