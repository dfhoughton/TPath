package TPath::Predicate::Attribute;

# ABSTRACT: implements the C<[@foo]> in C<//a/b[@foo]>

=head1 DESCRIPTION

The object that selects the correct member of collection based whether they have a particular attribute.

=cut

use Moose;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr a

The attribute evaluated.

=cut

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->a->test($_) } @$c;
}

sub to_string {
    $_[0]->a->to_string;
}

__PACKAGE__->meta->make_immutable;

1;
