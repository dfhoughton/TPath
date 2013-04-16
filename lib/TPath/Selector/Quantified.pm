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

sub to_string {
    my ( $self, $first ) = @_;
    my $bracket = $self->s->isa('TPath::Selector::Expression');
    for ( $self->quantifier ) {
        when ('e') {
            my $q;
            if ( $self->top == $self->bottom ) {
                $q = '{' . $self->top . '}';
            }
            elsif ( $self->bottom == 0 ) {
                $q = '{,' . $self->top . '}';
            }
            elsif ( $self->top == 0 ) {
                $q = '{' . $self->bottom . ',}';
            }
            else {
                $q = '{' . $self->bottom . ',' . $self->top . '}';
            }
            return '(' . $self->s->to_string($first) . ")$q" if $bracket;
            return $self->s->to_string($first) . $q;
        }
        when ('?') {
            return '(' . $self->s->to_string($first) . ')?' if $bracket;
            return $self->s->to_string($first) . '?';
        }
        when ('+') {
            return '(' . $self->s->to_string($first) . ')+' if $bracket;
            return $self->s->to_string($first) . '+';
        }
        when ('*') {
            return '(' . $self->s->to_string($first) . ')*' if $bracket;
            return $self->s->to_string($first) . '*';
        }
    }
}

sub select {
    my ( $self, $ctx, $first ) = @_;
    my @c = $self->s->select( $ctx, $first );
    for ( $self->quantifier ) {
        when ('?') { return @c, $ctx }
        when ('*') { return @{ _iterate( $self->s, \@c ) }, $ctx }
        when ('+') { return @{ _iterate( $self->s, \@c ) } }
        when ('e') {
            my ( $s, $top, $bottom ) = ( $self->s, $self->top, $self->bottom );
            my $c = _enum_iterate( $s, \@c, $top, $bottom, 1 );
            return @$c, $self->bottom < 2 ? $ctx : ();
        }
    }
}

sub _enum_iterate {
    my ( $s, $c, $top, $bottom, $count ) = @_;
    my @next = map { $s->select($_) } @$c;
    my @return = $count++ >= $bottom ? @$c : ();
    unshift @return, @next
      if $count >= $bottom && ( !$top || $count <= $top );
    unshift @return, @{ _iterate( $s, \@next, $top, $bottom, $count ) }
      if !$top || $count < $top;
    return \@return;
}

sub _iterate {
    my ( $s, $c ) = @_;
    return [] unless @$c;
    my @next = map { $s->select($_) } @$c;
    return [ @{ _iterate( $s, \@next ) }, @$c ];
}

__PACKAGE__->meta->make_immutable;

1;
