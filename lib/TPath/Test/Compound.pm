package TPath::Test::Compound;

# ABSTRACT: role of TPath::Tests that combine multiple other tests under some boolean operator

use Moose::Role;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Test::Boolean>

=cut

with 'TPath::Test::Boolean';

=attr tests

Subsidiary L<TPath::Test> objects combined by this test.

=cut

has tests => ( is => 'ro', isa => 'ArrayRef[CondArg]', required => 1 );

sub _compound_to_string {
    my ( $self, $op ) = @_;
    my $s     = '(';
    my @tests = @{ $self->tests };
    $s .= $tests[0]->to_string;
    for my $t ( @tests[ 1 .. $#tests ] ) {
        $s .= " $op " . $t->to_string;
    }
    $s .= ')';
    return $s;
}

1;
