package TPath::Selector::Predicated;

# ABSTRACT: role of selectors that have predicates

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=cut

use v5.10;
use Moose::Role;
use TPath::TypeConstraints;
use TPath::Test::Node::Complement;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=attr predicates

Auto-deref'ed list of L<TPath::Predicate> objects that filter anything selected
by this selector.

=cut

has predicates => (
    is         => 'ro',
    isa        => 'ArrayRef[TPath::Predicate]',
    default    => sub { [] },
    auto_deref => 1
);

=method apply_predicates

Expects a list of L<TPath::Context> objects. Applies each predicate to this in turn
and returns the filtered list.

=cut

sub apply_predicates {
    my ( $self, @candidates ) = @_;
    for my $p ( $self->predicates ) {
        last unless @candidates;
        @candidates = $p->filter( \@candidates );
    }
    return @candidates;
}

around 'to_string' => sub {
    my ( $orig, $self, @args ) = @_;
    my $s = $self->$orig(@args);
    for my $p ( $self->predicates ) {
        $p = $p->to_string;
        $s .= $p =~ /\s/ ? "[ $p ]" : "[$p]";
    }
    return $s;
};

1;
