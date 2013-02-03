package TPath::Attributes::Standard;

# ABSTRACT : the standard collection of attributes available to any forester by default

use Moose::Role;

requires qw(kids children parent);

sub true {
    return 1;
}

sub false {
    return 0;
}

sub this {
    my ( $self, $n ) = @_;
    return $n;
}

sub uid {
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

sub echo {
    my ( $self, $n, $c, $i, $o ) = @_;
    return $o;
}

sub isLeaf {
    my ( $self, $n, $c, $i ) = @_;
    my @children = $self->kids( $n, $i );
    return !@children;
}

sub pick {
    my ( $self, $n, $c, $i, $collection, $index ) = @_;
    return $collection->[$index];
}

sub size {
    my ( $self, $n, $c, $i, $collection ) = @_;
    return scalar @$collection;
}

sub tsize {
    my ( $self, $n, undef, $i ) = @_;
    my $size = 1;
    for my $kid ( $self->children( $n, $i ) ) {
        $size += $self->tsize( $kid, undef, $i );
    }
    return $size;
}

sub width {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->isLeaf( $n, $c, $i );
    my $width = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        $width += $self->width( $kid, $c, $i );
    }
    return $width;
}

sub depth {
    my ( $self, $n, $c, $i ) = @_;
    return 0 if $self->isRoot( $n, $c, $i );
    my $depth = -1;
    do {
        $depth++;
        $n = $self->parent( $n, $i );
    } while ( defined $n );
    return $depth;
}

sub height {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->isLeaf( $n, $c, $i );
    my $max = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        my $m = $self->height( $kid, $c, $i );
        $max = $m if $m > $max;
    }
    return $max + 1;
}

sub isRoot {
    my ( $self, $n, $c, $i ) = @_;
    return $i->is_root($n);
}

sub null {
    return undef;
}

sub index {
    my ( $self, $n, $c, $i ) = @_;
    return -1 if $i->is_root($n);
    my @siblings = $self->kids( [ $self->parent( $i, $n ) ], $i );
    for my $index ( 0 .. $#siblings ) {
        return $index if $siblings[$index] == $n;
    }
    confess "$n not among children of its parent";
}

sub log {
    my ( $self, $n, $c, $i, @messages ) = @_;
    for my $m (@messages) {
        $self->log_stream->put($m);
    }
    return 1;
}

1;
