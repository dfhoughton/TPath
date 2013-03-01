package TPath::Attributes::Standard;

# ABSTRACT: the standard collection of attributes available to any forester by default

=head1 DESCRIPTION

C<TPath::Attributes::Standard> provides the attributes available to all foresters.
C<TPath::Attributes::Standard> is a role which is composed into L<TPath::Forester>.

=cut

use Moose::Role;
use MooseX::MethodAttributes::Role;
use Scalar::Util qw(refaddr);

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

sub standard_true : Attr(true) {
    return 1;
}

=method C<@false>

Returns a value, C<undef>, evaluating to false.

=cut

sub standard_false : Attr(false) {
    return undef;
}

=method C<@this>

Returns the node itself.

=cut

sub standard_this : Attr(this) {
    my ( $self, $n ) = @_;
    return $n;
}

=method C<@uid>

Returns a string representing the unique path in the tree leading to this node.
This consists of the index of the node among its parent's children concatenated
to the uid of its parent with C</> as a separator. The uid of the root node is
always C</>. That of its second child is C</1>. That of the first child of this
child is C</1/0>. And so on.

=cut

sub standard_uid : Attr(uid) {
    my ( $self, $n, $c, $i ) = @_;
    my @list;
    my $node = $n;
    while ( !$i->is_root($node) ) {
        my $ra       = refaddr $node;
        my $parent   = $self->parent( $node, $i );
        my @children = $self->children( $parent, $i );
        for my $index ( 0 .. $#children ) {
            if ( refaddr $children[$index] eq $ra ) {
                push @list, $index;
                last;
            }
        }
        $node = $parent;
    }
    return '/' . join( '/', @list );
}

=method C<@echo(//a)>

Returns is parameter. C<@echo> is useful because it can in effect turn anything
into an attribute. You want a predicate that passes when a path returns a node
set of a particular cardinality?

  //foo[@echo(bar) = 3]

Attribute test expressions like this require that the left and right operands be either
attributes or constants, but this is no restriction because C<@echo> turns everything
into an attribute.

=cut

sub standard_echo : Attr(echo) {
    my ( $self, $n, $c, $i, $o ) = @_;
    return $o;
}

=method C<@leaf>

Returns whether the node is without children.

=cut

sub standard_is_leaf : Attr(leaf) {
    my ( $self, $n, $c, $i ) = @_;
    return $i->f->is_leaf( $n, $i ) ? 1 : undef;
}

=method C<@pick(//foo,1)>

Takes a collection and an index and returns the indexed member of the collection.

=cut

sub standard_pick : Attr(pick) {
    my ( $self, $n, $c, $i, $collection, $index ) = @_;
    return $collection->[ $index // 0 ];
}

=method C<@size(//foo)>

Takes a collection and returns its size.

=cut

sub standard_size : Attr(size) {
    my ( $self, $n, $c, $i, $collection ) = @_;
    return scalar @$collection;
}

=method C<@size>

Returns the size of the tree rooted at the context node.

=cut

sub standard_tsize : Attr(tsize) {
    my ( $self, $n, undef, $i ) = @_;
    my $size = 1;
    for my $kid ( $self->children( $n, $i ) ) {
        $size += $self->standard_tsize( $kid, undef, $i );
    }
    return $size;
}

=method C<@width>

Returns the number of leave under the context node.

=cut

sub standard_width : Attr(width) {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->standard_is_leaf( $n, $c, $i );
    my $width = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        $width += $self->standard_width( $kid, $c, $i );
    }
    return $width;
}

=method C<@depth>

Returns the number of ancestors of the context node.

=cut

sub standard_depth : Attr(depth) {
    my ( $self, $n, $c, $i ) = @_;
    return 0 if $self->standard_is_root( $n, $c, $i );
    my $depth = -1;
    do {
        $depth++;
        $n = $self->parent( $n, $i );
    } while ( defined $n );
    return $depth;
}

=method C<@depth>

Returns the greatest number of generations, inclusive, separating this
node from a leaf. Leaf nodes have a height of 1, their parents, 2, etc.

=cut

sub standard_height : Attr(height) {
    my ( $self, $n, $c, $i ) = @_;
    return 1 if $self->standard_is_leaf( $n, $c, $i );
    my $max = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        my $m = $self->standard_height( $kid, $c, $i );
        $max = $m if $m > $max;
    }
    return $max + 1;
}

=method C<@root>

Returns whether the context node is the tree root.

=cut

sub standard_is_root : Attr(root) {
    my ( $self, $n, $c, $i ) = @_;
    return $i->is_root($n) ? 1 : undef;
}

=method C<@null>

Returns C<undef>. This is chiefly useful as an argument to other attributes. It will
always evaluate as false if used as a predicate.

=cut

sub standard_null : Attr(null) {
    return undef;
}

=method C<@index>

Returns the index of this node among its parent's children, or -1 if it is the root
node.

=cut

sub standard_index : Attr(index) {
    my ( $self, $n, $c, $i ) = @_;
    return -1 if $i->is_root($n);
    my @siblings = $self->_kids( $self->parent( $n, $i ), $i );
    for my $index ( 0 .. $#siblings ) {
        return $index if refaddr $siblings[$index] eq refaddr $n;
    }
    confess "$n not among children of its parent";
}

=method C<@log('m1','m2','m3','...')>

Prints each message argument to the log stream, one per line, and returns 1.
See attribute C<log_stream> in L<TPath::Forester>.

=cut

sub standard_log : Attr(log) {
    my ( $self, $n, $c, $i, @messages ) = @_;
    for my $m (@messages) {
        $self->log_stream->put($m);
    }
    return 1;
}

=method C<@id>

Returns the id of the current node, if any.

=cut

sub standard_id : Attr(id) {
    my ( $self, $n, $c, $i ) = @_;
    $self->id($n);
}

1;
