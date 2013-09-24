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

    # my ( $self, $ctx ) = @_;
    (
        $_[0]->_cr // $_[0]->_cr(
            do {
                my $f   = $_[1]->i->f;
                my $tag = $_[0]->tag;
                my $sr  = $f->can('has_tag');
                sub { $sr->( $f, $_[0], $tag ) };
              }
        )
    )->( $_[1][0] );
}

__PACKAGE__->meta->make_immutable;

1;
