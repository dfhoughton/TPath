package TPath::Predicate::Boolean;

# ABSTRACT: implements the C<[@foo or @bar ]> in C<//a/b[@foo or @bar]>

=head1 DESCRIPTION

The object that selects the correct members of collection based on whether a boolean expression evaluated with
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

has t => ( is => 'ro', does => 'TPath::Test', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->t->test($_) } @$c;
}

sub to_string { $_[0]->t->to_string }

__PACKAGE__->meta->make_immutable;

1;
