package MyAttributes;

use Moose::Role;
use MooseX::MethodAttributes::Role;

sub attr : Attr {
    my ( $self, $n, $i, $c, $name ) = @_;
    $n->attribute($name);
}

sub te : Attr {
    my ( $self, $n, $i, $c, $name ) = @_;
    $n->tag eq $name ? 1 : undef;
}

package ToyXMLForester;

use Moose;
use MooseX::MethodAttributes;
use namespace::autoclean;
use TPath::Index;

with qw(TPath::Forester MyAttributes);

sub children { my ( $self, $n ) = @_; $n->children }
sub tag : Attr    { my ( $self, $n ) = @_; $n->tag }
sub id { my ( $self, $n ) = @_; $n->attribute('id') }

sub BUILD { $_[0]->_node_type('Element') }

__PACKAGE__->meta->make_immutable;

1;
