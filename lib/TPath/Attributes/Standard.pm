package TPath::Attributes::Standard;

# ABSTRACT: the standard collection of attributes available to any forester by default

=head1 DESCRIPTION

C<TPath::Attributes::Standard> provides the attributes available to all foresters.
C<TPath::Attributes::Standard> is a role which is composed into L<TPath::Forester>.

=cut

use v5.10;
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
    my ( undef, $n ) = @_;
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
    my ( $self, $n, $i ) = @_;
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

Returns its parameter. C<@echo> is useful because it can in effect turn anything
into an attribute. You want a predicate that passes when a path returns a node
set of a particular cardinality?

  //foo[@echo(bar) = 3]

Attribute test expressions like this require that the left and right operands be either
attributes or constants, but this is no restriction because C<@echo> turns everything
into an attribute.

=cut

sub standard_echo : Attr(echo) {
    my ( undef, undef, undef, undef, $o ) = @_;
    return $o;
}

=method C<@leaf>

Returns whether the node is without children.

=cut

sub standard_is_leaf : Attr(leaf) {
    my ( undef, $n, $i ) = @_;
    return $i->f->is_leaf( $n, $i ) ? 1 : undef;
}

=method C<@pick(//foo,1)>

Takes a collection and an index and returns the indexed member of the collection.

=cut

sub standard_pick : Attr(pick) {
    my ( undef, undef, undef, undef, $collection, $index ) = @_;
    return $collection->[ $index // 0 ];
}

=method C<@size(//foo)>

Takes a collection and returns its size.

=cut

sub standard_size : Attr(size) {
    my ( undef, undef, undef, undef, $collection ) = @_;
    return scalar @$collection;
}

=method C<@size>

Returns the size of the tree rooted at the context node.

=cut

sub standard_tsize : Attr(tsize) {
    my ( $self, $n, $i ) = @_;
    my $size = 1;
    for my $kid ( $self->children( $n, $i ) ) {
        $size += $self->standard_tsize( $kid, $i );
    }
    return $size;
}

=method C<@width>

Returns the number of leave under the context node.

=cut

sub standard_width : Attr(width) {
    my ( $self, $n, $i ) = @_;
    return 1 if $self->standard_is_leaf( $n, $i );
    my $width = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        $width += $self->standard_width( $kid, $i );
    }
    return $width;
}

=method C<@depth>

Returns the number of ancestors of the context node.

=cut

sub standard_depth : Attr(depth) {
    my ( $self, $n, $i ) = @_;
    return 0 if $self->standard_is_root( $n, $i );
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
    my ( $self, $n, $i ) = @_;
    return 1 if $self->standard_is_leaf( $n, $i );
    my $max = 0;
    for my $kid ( $self->children( $n, $i ) ) {
        my $m = $self->standard_height( $kid, $i );
        $max = $m if $m > $max;
    }
    return $max + 1;
}

=method C<@root>

Returns whether the context node is the tree root.

=cut

sub standard_is_root : Attr(root) {
    my ( $self, $n, $i ) = @_;
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
    my ( $self, $n, $i ) = @_;
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
    my ( $self, undef, undef, undef, @messages ) = @_;
    for my $m (@messages) {
        $self->log_stream->put($m);
    }
    return 1;
}

=method C<@id>

Returns the id of the current node, if any.

=cut

sub standard_id : Attr(id) {
    my ( $self, $n ) = @_;
    $self->id($n);
}

=method C<@card(//a)>

Returns the cardinality of its parameter. If its parameter evaluates to a list reference, it is the
number of items in the list. If it evaluates to a hash reference, it is the number of mappings. The
usual parameters are expressions or attributes. Anything which evaluates to C<undef> will have a
cardinality of 0. Anything which does not evaluate to a collection reference will have a cardinality
of 1. 

  //foo[@card(bar) = @card(@quux)]

=cut

sub standard_card : Attr(card) {
    my ( undef, undef, undef, undef, $o ) = @_;
    return 0 unless defined $o;
    for (ref $o) {
        when ('HASH') {return scalar keys %$o } 
        when ('ARRAY') {return scalar @$o}
        default { return 1 }
    }
}

=method C<@at(foo//bar, 'baz', 1, 2, 3)>

Returns the value of the named attribute with the given parameters at the first node selected by
the path parameter evaluated relative to the context node. In the case of

  @at(foo//bar, 'baz', 1, 2, 3)

The path parameter is C<foo//bar>, the relevant attribute is C<@baz>, and it will be evaluated using
the parameters 1, 2, and 3. Other examples:

  @at(leaf::*[1], 'id')   # the id of the second leaf under this node
  @at(*/*, 'height')      # the height of the first grandchild of this node
  @at(/>foo, 'depth')     # the depth of the closest foo node

It is the first node selected by the path whose attribute is evaluated, that is, the first node returned,
so it is relevant that paths are evaluated left-to-right, depth-first, and post-ordered, descendants being
returned before their ancestors.

=cut

sub standard_attr :Attr(at) {
    my ( $self, $n, $i, $c, $nodes, $attr, @params ) = @_;
    my @nodes = @$nodes;
    return undef unless @nodes;
    $self->attribute($nodes[0], $attr, $i, $c, @params);
}

1;
