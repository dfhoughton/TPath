package TPath::Selector::Test::RootAxisWildcard;

# ABSTRACT: handles C</ancestor::*> or C</preceding::*> where this is the first step in the path

use feature 'state';
use Moose;
use namespace::autoclean;

extends 'TPath::Selector::Test::AxisWildcard';

sub candidates {
    $self->SUPER::candidates( $i->root, $c, $i );
}

__PACKAGE__->meta->make_immutable;

1;
