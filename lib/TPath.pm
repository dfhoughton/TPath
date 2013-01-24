# ABSTRACT: general purpose path languages for trees

package TPath;

use Modern::Perl;
use Moose;
use Carp;
use namespace::autoclean -also => qr/^_/;

use TPath::Step;

has class => (
is => 'ro',
isa => 'Str',
required => 1,
);

has steps => (
is => 'ro',
isa => 'ArrayRef[TPath::Step]',
required => 1,
);

=method select

takes a node of the appropriate class and returns the nodes
selected by this path using the given node as a context node

=cut

sub select {
my ($self, $node) = @_;
confess "can only handle ".$self->class." nodes" unless $node->isa($self->class);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
