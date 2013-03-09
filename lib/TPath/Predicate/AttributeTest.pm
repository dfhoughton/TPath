package TPath::Predicate::AttributeTest;

# ABSTRACT: implements the C<[@foo = 1]> in C<//a/b[@foo = 1]>

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
    my ( $self, $i, $c ) = @_;
    return grep { $self->at->test($_, $i, $c) } @$c;
}

__PACKAGE__->meta->make_immutable;

1;
