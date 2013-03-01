package TPath::Test::And;

# ABSTRACT: implements logical conjunction of tests

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;

=head1 ROLES

L<TPath::Test::Compound>

=cut

with 'TPath::Test::Compound';

# required by TPath::Test
sub test {
    my ( $self, $n, $c, $i ) = @_;
    for my $t ( @{ $self->tests } ) {
        return 0 unless $t->test( $n, $c, $i );
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
