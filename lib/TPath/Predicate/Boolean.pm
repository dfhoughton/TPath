package TPath::Predicate::Boolean;

# ABSTRACT: implements the C<[@foo or @bar ]> in C<//a/b[@foo or @bar]>

=head1 DESCRIPTION

The object that selects the correct members of collection based whether a boolean expression evaluated with
them as the context returns a true value.

=cut

use Moose;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr t

The L<TPath::Test> evaluated by the predicate.

=cut

has t => ( is => 'ro', isa => 'TPath::Test', required => 1 );

sub filter {
    my ( $self, $c, $i ) = @_;
    return grep { $self->t->test($_, $c, $i) } @$c;
}

__PACKAGE__->meta->make_immutable;

1;
