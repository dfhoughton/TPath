package TPath::Test::Or;

# ABSTRACT: implements logical disjunction of tests

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;

=head1 ROLES

L<TPath::Test::Compound>

=cut

with 'TPath::Test::Compound';

=method test

Returns true if any subsidiary test is true.

=cut

sub test {
    my ( $self, $n, $c, $i ) = @_;
    for my $t ( @{ $self->tests } ) {
        return 1 if $t->test( $n, $c, $i );
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
