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

    # my ( $self, $ctx ) = @_;
    (
        $_[0]->_cr // $_[0]->_cr(
            do {
                my $f  = $_[1]->i->f;
                my $rx = $_[0]->rx;
                my $sr = $f->can('matches_tag');
                sub { $sr->( $f, $_[0], $rx ) };
              }
        )
    )->( $_[1][0] );
}

__PACKAGE__->meta->make_immutable;

1;
