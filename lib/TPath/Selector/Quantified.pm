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

sub select {
	my ( $self, $n, $i, $first ) = @_;
	my @c = $self->s->select( $n, $i, $first );
	for ( $self->quantifier ) {
		when ('?') { return @c, $n }
		when ('*') { return @{ _iterate( $self->s, $first, $i, \@c ) }, $n }
		when ('+') { return @{ _iterate( $self->s, $first, $i, \@c ) } }
	}
}

sub _iterate {
	my ( $s, $first, $i, $c ) = @_;
	return [] unless @$c;
	my @next = map { $s->select( $_, $i, $first ) } @$c;
	return [ @{ _iterate( $s, $first, $i, \@next ) }, @$c ];
}

__PACKAGE__->meta->make_immutable;

1;
