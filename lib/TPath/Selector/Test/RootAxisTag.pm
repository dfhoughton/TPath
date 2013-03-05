package TPath::Selector::Test::RootAxisTag;

# ABSTRACT: handles C</ancestor::foo> or C</preceding::foo> where this is the first step in the path

use feature 'state';
use Moose;
use namespace::autoclean;

extends 'TPath::Selector::Test::AxisTag';

sub candidates {
    my ( $self, undef, $c, $i ) = @_;
    $self->SUPER::candidates( $i->root, $c, $i );
}

__PACKAGE__->meta->make_immutable;

1;
