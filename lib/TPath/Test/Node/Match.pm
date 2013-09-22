package TPath::Test::Node::Match;

# ABSTRACT: L<TPath::Test::Node> implementing matching; e.g., C<//~foo~>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr rx

Pattern to match.

=cut

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {
    my ( $self, $ctx ) = @_;
    ( $self->_cr // $self->set_cr( $ctx->i->f ) )->( $ctx->n );
}

sub set_cr {
    my ( $self, $f ) = @_;
    my $rx = $self->rx;
    my $sr  = $f->can('matches_tag');
    $self->_cr( sub { $sr->( $f, shift, $rx ) } );
}

__PACKAGE__->meta->make_immutable;

1;
