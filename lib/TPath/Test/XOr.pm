package TPath::Test::XOr;

# ABSTRACT : implements logical function of tests which returns true iff only one test is true

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;
use TPath::Test;

with 'TPath::Test';

has tests => ( is => 'ro', isa => 'ArrayRef[TPath::Test]', required => 1 );

sub test {
    my ( $self, $n, $c, $i ) = @_;
    my $count = 0;
    for my $t ( @{ $self->tests } ) {
        if ( $t->test( $n, $c, $i ) ) {
            return 0 if $count;
            $count++;
        }
    }
    return $count;
}

__PACKAGE__->meta->make_immutable;

1;
