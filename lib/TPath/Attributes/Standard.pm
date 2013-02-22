package TPath::Attributes::Standard;

# ABSTRACT: the standard collection of attributes available to any forester by default

# TODO document methods

use Moose::Role;
use MooseX::MethodAttributes::Role;

=head1 REQUIRED METHODS

=head2 _kids

See L<TPath::Forester>

=head2 children

See L<TPath::Forester>

=head2 parent

See L<TPath::Forester>

=cut

requires qw(_kids children parent);

=method C<@true>

Returns a value, 1, evaluating to true.

=cut

sub true : Attr {
    return 1;
}

=method C<@false>

Returns a value, C<undef>, evaluating to false.

=cut

sub false : Attr {
    return undef;
}

=method C<@this>

Returns the node itself.

=cut

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

=method C<@null>

Returns C<undef>. This is chiefly useful as an argument to other attributes. It will
always evaluate as false if used as a predicate.

=cut

sub null : Attr {
    return undef;
}

=method idx => C<@index>

Returns the index of this node among its parent's children, or -1 if it is the root
node.

=cut

sub idx : Attr(index) {
    my ( $self, $n, $c, $i ) = @_;
    return -1 if $i->is_root($n);
    my @siblings = $self->_kids( [ $self->parent( $i, $n ) ], $i );
    for my $index ( 0 .. $#siblings ) {
        return $index if $siblings[$index] == $n;
    }
    confess "$n not among children of its parent";
}

=method C<@log('m1','m2','m3','...')>

Prints each message argument to the log stream, one per line, and returns 1.
See attribute C<log_stream> in L<TPath::Forester>.

=cut

sub log : Attr {
    my ( $self, $n, $c, $i, @messages ) = @_;
    for my $m (@messages) {
        $self->log_stream->put($m);
    }
    return 1;
}

=method nid => C<@id>

Returns the id of the current node, if any.

=cut

sub nid : Attr(id) {
    my ( $self, $n, $c, $i ) = @_;
    $self->id($n);
}

1;
