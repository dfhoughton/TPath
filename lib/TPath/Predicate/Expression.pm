package TPath::Predicate::Expression;

# ABSTRACT: implements the C<[c]> in C<//a/b[c]>

=head1 DESCRIPTION

The object that selects the correct members of collection based whether an expression evaluated with
them as the context selects a non-empty set of nodes.

=cut

use Moose;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr e

The L<TPath::Expression> evaluated by the predicate.

=cut

has e => ( is => 'ro', isa => 'TPath::Expression', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->e->test($_) } @$c;
}

sub to_string {
    $_[0]->e->to_string;
}

__PACKAGE__->meta->make_immutable;

1;
