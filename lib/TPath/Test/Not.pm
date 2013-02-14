package TPath::Test::Not;

# ABSTRACT : implements logical negation of a test

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;
use TPath::Test;

=head1 ROLES

L<TPath::Test::Boolean>

=cut

with 'TPath::Test::Boolean';

=attr test

The single test the negation of which will provide the value of this L<TPath::Test>.

=cut

has test => ( is => 'ro', isa => 'TPath::Test', required => 1 );

=method test

Returns the negation of whether the C<test> attribute is true.

=cut

sub test {
    my ( $self, $n, $c, $i ) = @_;
    return !$self->test( $n, $c, $i );
}

__PACKAGE__->meta->make_immutable;

1;
