package TPath::Selector::Expression;

# ABSTRACT: selector that handles the parenthesized portion of C<a(/foo|/bar)> and C<a(/foo|/bar)+>

=head1 DESCRIPTION

A selector that handles grouped steps as in C<a(/foo|//bar)?/baz>. This does not handle the quantification, which is
delegated to L<TPath::Selector::Quantified>.

=cut

use v5.10;
use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=attr e

The expression within the group.

=cut

has e => ( is => 'ro', isa => 'TPath::Expression', required => 1 );

sub select {
    my ( $self, $ctx, $first ) = @_;
    return @{ $self->e->_select( $ctx, $first ) };
}

sub to_string {
    my $self = shift;
    return $self->e->to_string;
}

__PACKAGE__->meta->make_immutable;

1;
