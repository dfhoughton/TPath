package TPath::Selector::Quantified;

# ABSTRACT: handles expressions like C<a?> and C<//foo*>

=head1 DESCRIPTION

Selector that applies a quantifier to an ordinary selector.

=cut

use v5.10;
use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=attr s

The selector to which the quantifier is applied.

=cut

has s => ( is => 'ro', isa => 'TPath::Selector', required => 1 );

=attr quantifier

The quantifier.

=cut

has quantifier => ( is => 'ro', isa => 'Quantifier', required => 1 );

=attr top

The largest number of iterations permitted. If 0, there is no limit. Used only by
the C<{x,y}> quantifier.

=cut

has top => ( is => 'ro', isa => 'Int', default => 0 );

=attr bottom

The smallest number of iterations permitted. Used only by the C<{x,y}> quantifier.

=cut

has bottom => ( is => 'ro', isa => 'Int', default => 0 );

sub select {
	my ( $self, $n, $i, $first ) = @_;
	my @c = $self->s->select( $n, $i, $first );
	for ( $self->quantifier ) {
		when ('?') { return @c, $n }
		when ('*') { return @{ _iterate( $self->s, $i, \@c ) }, $n }
		when ('+') { return @{ _iterate( $self->s, $i, \@c ) } }
		when ('e') {
			my ( $s, $top, $bottom ) =
			  ( $self->s, $self->top, $self->bottom );
			my $c = _enum_iterate( $s, $i, \@c, $top, $bottom, 1 );
			return @$c, $self->bottom < 2 ? $n : ();
		}
	}
}

sub _enum_iterate {
	my ( $s, $i, $c, $top, $bottom, $count ) = @_;
	my @next = map { $s->select( $_, $i ) } @$c;
	my @return = $count++ >= $bottom ? @$c : ();
	unshift @return, @next
	  if $count >= $bottom && ( !$top || $count <= $top );
	unshift @return, @{ _iterate( $s, $i, \@next, $top, $bottom, $count ) }
	  if !$top || $count < $top;
	return \@return;
}

sub _iterate {
	my ( $s, $i, $c, $top, $bottom, $count ) = @_;
	return [] unless @$c;
	my @next = map { $s->select( $_, $i ) } @$c;
	return [ @{ _iterate( $s, $i, \@next ) }, @$c ];
}

__PACKAGE__->meta->make_immutable;

1;
