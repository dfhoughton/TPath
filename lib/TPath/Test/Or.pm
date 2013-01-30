package TPath::Test::Or;

# ABSTRACT : implements logical disjunction of tests

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;
use TPath::Test;

with 'TPath::Test';

has tests => ( is => 'ro', isa => 'ArrayRef[TPath::Test]', required => 1 );

sub test {
    my ( $self, $n, $c, $i ) = @_;
    for my $t ( @{ $self->tests } ) {
        return 1 if $t->test( $n, $c, $i );
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
