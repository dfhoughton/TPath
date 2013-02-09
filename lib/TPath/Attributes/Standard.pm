package TPath::Attributes::Standard;

# ABSTRACT : the standard collection of attributes available to any forester by default

use Moose::Role;
use MooseX::MethodAttributes::Role;

requires qw(_kids children parent);

sub true : Attr {
    return 1;
}

sub false : Attr {
    return 0;
}

sub this : Attr {
    my ( $self, $n ) = @_;
    return $n;
}

sub uid : Attr {
    my ( $self, $n, $c, $i ) = @_;
    my @list;
    my $node = $n;
    while ( !$i->is_root($node) ) {
        my $parent = $self->parent( $n, $i );
        my @children = $self->children( $parent, $i );
        for my $index ( 0 .. $#children ) {
            if ( $children[$index] == $node ) {
                push @list, $index;
                last;
            }
        }
        $node = $parent;
    }
    return '/' . join( '/', @list );
}

sub echo : Attr {
    my ( $self, $n, $c, $i, $o ) = @_;
    return $o;
}

sub isLeaf : Attr {
    my ( $self, $n, $c, $i ) = @_;
    my @children = $self->_kids( $n, $i );
    return !@children;
}

sub pick : Attr {
    my ( $self, $n, $c, $i, $collection, $index ) = @_;
    return $collection->[$index];
}

sub size : Attr {
    my ( $self, $n, $c, $i, $collection ) = @_;
    return scalar @$collection;
}

sub tsize : Attr {
    my ( $self, $n, undef, $i ) = @_;
    my $size = 1;
    for my $kid ( $self->children( $n, $i ) ) {
        $size += $self->tsize( $kid, undef, $i );
    }
    return $size;
}

sub width : Attr {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->isLeaf( $n, $c, $i );
    my $width = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        $width += $self->width( $kid, $c, $i );
    }
    return $width;
}

sub depth : Attr {
    my ( $self, $n, $c, $i ) = @_;
    return 0 if $self->isRoot( $n, $c, $i );
    my $depth = -1;
    do {
        $depth++;
        $n = $self->parent( $n, $i );
    } while ( defined $n );
    return $depth;
}

sub height : Attr {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->isLeaf( $n, $c, $i );
    my $max = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        my $m = $self->height( $kid, $c, $i );
        $max = $m if $m > $max;
    }
    return $max + 1;
}

sub isRoot : Attr {
    my ( $self, $n, $c, $i ) = @_;
    return $i->is_root($n);
}

sub null : Attr {
    return undef;
}

sub index : Attr {
    my ( $self, $n, $c, $i ) = @_;
    return -1 if $i->is_root($n);
    my @siblings = $self->_kids( [ $self->parent( $i, $n ) ], $i );
    for my $index ( 0 .. $#siblings ) {
        return $index if $siblings[$index] == $n;
    }
    confess "$n not among children of its parent";
}

sub log : Attr {
    my ( $self, $n, $c, $i, @messages ) = @_;
    for my $m (@messages) {
        $self->log_stream->put($m);
    }
    return 1;
}

1;
