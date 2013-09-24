package TPath::Test::Node::Complement;

# ABSTRACT: L<TPath::Test::Node> implementing matching; e.g., C<//^~foo~>, C<//^foo>, and C<//^@foo>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr a

Attribute to detect.

=cut

has nt => ( is => 'ro', isa => 'TPath::Test::Node', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {
    return (
        $_[0]->_cr // do {
            my $nt     = $_[0]->nt;
            my $passes = $nt->can('passes');
            $_[0]->_cr( sub { $passes->( $nt, $_[0] ) ? undef : 1 } );
          }
    )->( $_[1] );

    # my ( $self, $ctx ) = @_;
    # return $_[0]->nt->passes( $_[1] ) ? undef : 1;
}

__PACKAGE__->meta->make_immutable;

1;
