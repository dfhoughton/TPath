package TPath::Test::One;

# ABSTRACT: implements logical function of tests which returns true iff only one test is true

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=cut

use Moose;

with 'TPath::Test::Compound';

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    my $count = 0;
    for my $t ( @{ $self->tests } ) {
        if ( $t->test($ctx) ) {
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
