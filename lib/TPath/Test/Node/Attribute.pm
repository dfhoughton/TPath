package TPath::Test::Node::Attribute;

# ABSTRACT: L<TPath::Test::Node> implementing attributes; e.g., C<//@foo>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr a

Attribute to detect.

=cut

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {

    # my ( $self, $ctx ) = @_;
    return (
        $_[0]->_cr // do {
            my $a     = $_[0]->a;
            my $apply = $a->can('apply');
            $_[0]->_cr( sub { $apply->( $a, $_[0] ) ? 1 : undef } );
          }
    )->( $_[1] );
}

sub to_string { $_[0]->a->to_string }

__PACKAGE__->meta->make_immutable;

1;
