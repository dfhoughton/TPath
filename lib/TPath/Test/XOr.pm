package TPath::Test::XOr;

# ABSTRACT: implements logical function of tests which returns true iff only one test is true

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

NOTE: though this is called C<TPath::Test::XOr> it corresponds to the C<`> operator
and is really best understood as a one-of or uniqueness test. If it governs two operands,
it is logically equivalent to exclusive or. If it governs more than one, it is B<not> necessarily
equivalent to evaluating a sequence of pairwise exclusive or constructs. I have written things
this way because I figure this is more useful in general and the true exclusive or logic can
be recreated easily enough by adding parentheses to group operands.

=cut

use Moose;

with 'TPath::Test::Compound';

# required by TPath::Test
sub test {
    my ( $self, $n, $i, $c ) = @_;
    my $count = 0;
    for my $t ( @{ $self->tests } ) {
        if ( $t->test( $n, $i, $c ) ) {
            return 0 if $count;
            $count++;
        }
    }
    return $count;
}

sub to_string {
    my $self = shift;
    return $self->_compound_to_string(';');
}

__PACKAGE__->meta->make_immutable;

1;
