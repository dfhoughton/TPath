package ToyXMLForester;

use Moose;
use namespace::autoclean;
use TPath::Index;

with 'TPath::Forester';

sub children { my ( $self, $n ) = @_; $n->children }
sub has_tag     { my ( $self, $n, $tag ) = @_; $n->tag eq $tag }
sub matches_tag { my ( $self, $n, $rx )  = @_; $n->tag =~ $rx }
sub parent { my ( $self, $n ) = @_; $n->parent }

sub BUILD { $_[0]->_node_type('Element') }

__PACKAGE__->meta->make_immutable;

1;
