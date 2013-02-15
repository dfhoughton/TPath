# our basic tree element for use in testing

package Element;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Moose;

use overload '""' => sub { $_[0]->to_string }, fallback => 1;

has tag => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has children => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
    auto_deref => 1,
);

has attributes => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub { {} },
);

has parent => (
    is       => 'ro',
    isa      => 'Maybe[Element]',
    weak_ref => 1,
    required => 1,
);

has id => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { refaddr $_[0] },
);

sub to_string {
    my $self = shift;
    my $s    = '<' . $self->tag;
    while ( my ( $k, $v ) = each %{ $self->attributes } ) {
        $s .= " $k=\"$v\"";
    }
    my @children = @{ $self->children };
    if (@children) {
        $s .= '>';
        $s .= $_ for @children;
        $s .= '</' . $self->tag . '>';
    }
    else {
        $s .= '/>';
    }
    return $s;
}

sub child {
    my ( $self, $i, $child ) = @_;
    $self->children->[$i] = $child if defined $child;
    return $self->children->[$i];
}

sub attribute {
    my ( $self, $key, $value ) = @_;
    $self->attributes->{$key} = $value if defined $value;
    return $self->attributes->{$key};
}

sub has_attribute {
    my ( $self, $key ) = @_;
    return exists $self->attributes->{$key};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
