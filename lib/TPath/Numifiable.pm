package TPath::Numifiable;

# ABSTRACT: role of things that evaluate to numbers

use Moose::Role;

=head1 ROLES

L<TPath::Stringifiable>

=cut

with 'TPath::Stringifiable';

=attr negated

Whether the expressions is negated.

=cut

has negated => ( is => 'ro', isa => 'Bool', default => 0 );

=head1 REQUIRED METHODS

=head2 C<to_num($ctx)>

Takes a L<TPath::Context> and returns a number.

=cut

requires 'to_num';

around to_num => sub {
    my ( $orig, $self, $ctx ) = @_;
    my $v = $self->$orig($ctx);
    return $self->negated ? -$v : $v;
};

1;
