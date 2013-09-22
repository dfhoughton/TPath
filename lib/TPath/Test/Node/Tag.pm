package TPath::Test::Node::Tag;

# ABSTRACT: L<TPath::Test::Node> implementing basic tag pattern; e.g., C<//foo>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr tag

Tag or value to match.

=cut

has tag => ( is => 'ro', isa => 'Str', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {
    my ( $self, $ctx ) = @_;
    ( $self->_cr // $self->set_cr( $ctx->i->f ) )->( $ctx->n );
}

sub set_cr {
    my ( $self, $f ) = @_;
    my $tag = $self->tag;
    my $sr  = $f->can('has_tag');
    $self->_cr( sub { $sr->( $f, shift, $tag ) } );
}

__PACKAGE__->meta->make_immutable;

1;
