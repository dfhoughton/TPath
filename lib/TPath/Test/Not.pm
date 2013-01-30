package TPath::Test::Not;

# ABSTRACT : implements logical negation of a test

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;
use TPath::Test;

with 'TPath::Test';

has test => ( is => 'ro', isa => 'TPath::Test', required => 1 );

sub test {
    my ( $self, $n, $c, $i ) = @_;
    return !$self->test( $n, $c, $i );
}

__PACKAGE__->meta->make_immutable;

1;
