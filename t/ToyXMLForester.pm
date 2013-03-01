package MyAttributes;

use Moose::Role;
use MooseX::MethodAttributes::Role;

sub attr : Attr {
    my ( $self, $n, $c, $i, $name ) = @_;
    $n->attribute($name);
}

sub tag : Attr {
    my ( $self, $n, $c, $i, $name ) = @_;
    $n->tag;
}

sub te : Attr {
    my ( $self, $n, $c, $i, $name ) = @_;
    $n->tag eq $name ? 1 : undef;
}

package ToyXMLForester;

use Moose;
use namespace::autoclean;
use TPath::Index;

with qw(TPath::Forester MyAttributes);

sub children { my ( $self, $n ) = @_; $n->children }
sub has_tag     { my ( $self, $n, $tag ) = @_; $n->tag eq $tag }
sub matches_tag { my ( $self, $n, $rx )  = @_; $n->tag =~ $rx }
sub id { my ( $self, $n ) = @_; $n->attribute('id') }

sub BUILD { $_[0]->_node_type('Element') }

__PACKAGE__->meta->make_immutable;

1;
