package TPath::Predicate::AttributeTest;

# ABSTRACT: implements the [@foo = 1] in //a/b[@foo = 1]

=head1 DESCRIPTION

The object that selects the correct member of collection based whether they pass a particular attribute test.

=cut

use Moose;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr at

The L<TPath::AttributeTest> selected items must pass.

=cut

has at => ( is => 'ro', isa => 'TPath::AttributeTest', required => 1 );

sub filter {
    my ( $self, $c, $i ) = @_;
    return grep { $self->at->test($_, $c, $i) } @$c;
}

__PACKAGE__->meta->make_immutable;

1;
