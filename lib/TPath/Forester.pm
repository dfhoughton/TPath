package TPath::Forester;

# ABSTRACT: a generator of TPath expressions for a particular class of nodes

=head1 SYNOPSIS

  # we apply the TPath::Forester role to a class

  {
    package MyForester;

    use Moose;                                      # for simplicity we omit removing Moose droppings, etc.
    use MooseX::MethodAttributes;                   # needed if you're going to add some attributes

    with 'TPath::Forester';                         # compose in the TPath::Forester methods and attributes

    # define abstract methods
    sub children    { $_[1]->children }             # our nodes know their children
    sub parent      { $_[1]->parent }               # our nodes know their parent
    sub has_tag     {                               # our nodes have a tag attribute which is
       my ($self, $node, $tag) = @_;                #   their only tag
       $node->tag eq $tag;
    }
    sub matches_tag { 
       my ($self, $node, $re) = @_;
       $node->tag =~ $re;
    }

    # define an attribute
    sub baz :Attr   {   
      # the canonical order of arguments, none of which we need
      # my ($self, $node, $collection, $index, @args) = @_;
      'baz';
    }
  }

  # now select some nodes from a tree

  my $f     = MyForester->new;                      # make a forester
  my $path  = $f->path('//foo/>bar[@depth = 4]');   # compile a path
  my $root  = fetch_tree();                         # get a tree of interest
  my @nodes = $path->select($root);                 # find the nodes of interest

  # say our nodes have a text method that returns a string

  $f->add_test( sub { shift->text =~ /^\s+$/ } );   # ignore whitespace nodes
  $f->add_test( sub { shift->text =~ /^-?\d+$/ } ); # ignore integers
  $f->add_test( sub { ! length shift->text } );     # ignore empty nodes

  # reset to ignoring nothing

  $f->clear_tests;

=head1 DESCRIPTION

A C<TPath::Forester> understands your trees and hence can translate TPath expressions
into objects that will select the appropriate nodes from your trees. It can also generate
an index appropriate to your trees if you're doing multiple selects on a particular tree.

C<TPath::Forester> is a role. It provides most, but not all, methods and attributes
required to construct L<TPath::Expression> objects. You must specify how to find a node's
children and its parent (you may have to rely on a L<TPath::Index> for this), and you
must define how a tag string or regex may match a node, if at all.

=cut

use Moose::Role;

use TPath::Compiler qw(compile);
use TPath::Grammar qw(parse);
use TPath::StderrLog;
use TPath::Test::Node::True;

=head1 ROLES

L<TPath::Attributes::Standard>

=cut

with 'TPath::Attributes::Standard';

=head1 REQUIRED METHODS

=head2 children

Expects a node and an index. Returns the children of the node as a list.

=head2 has_tag

Expects a node and a string. Returns whether the node, in whatever sense is appropriate
to this sort of node, "has" the string as a tag.

=head2 matches_tag

Expects a node and a compiled regex. Returns whether the node, in whatever sense is appropriate
to this sort of node, has a tag that matches the regex.

=head2 parent

Expects a node and an index. Returns the parent of the node.

=cut

requires qw(children has_tag matches_tag parent);

=attr log_stream

A L<TPath::LogStream> required by the C<@log> attribute. By default it is L<TPath::StderrLog>.

=cut

has log_stream => (
    is      => 'rw',
    isa     => 'TPath::LogStream',
    default => sub { TPath::StderrLog->new }
);

=method add_test, clear_tests

Add a code ref that will be used to test whether a node is ignorable. The
return value of this code will be treated as a boolean value. If it is true,
the node, and all its children, will be passed over as possible items to return
from a select.

This method has the companion method C<clear_tests>, which empties the test list.

=cut

has _tests => (
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    default => sub { [] },
    handles => {
        add_test    => 'push',
        _tests      => 'elements',
        clear_tests => 'clear',
    }
);

has _attributes => (
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    lazy    => 1,
    builder => '_collect_attributes'
);

sub _collect_attributes {
    my $self       = shift;
    my $class      = ref $self;
    my %attributes = ();
    for my $method ( $class->meta->get_all_methods ) {
        next unless $method->can('attributes');
        my @annotations = grep /^Attr\b/, @{ $method->attributes };
        if (@annotations) {
            my $annotation = shift @annotations;
            if ( $annotation eq 'Attr' ) {
                $attributes{ $method->name } = $method->body;
            }
            else {
                require URI::Escape;
                if ( $annotation =~ /^Attr\(([^():]++)\)$/ ) {
                    my $alias = URI::Escape::uri_unescape($1);
                    $attributes{$alias} = $method->body;
                }
                else {
                    confess "malformed annotation $annotation in method "
                      . $method->name;
                }
            }
        }
    }
    return \%attributes;
}

=method path

Takes a TPath expression and returns a L<TPath::Expression>.

=cut

sub path {
    my ( $self, $expr ) = @_;
    my $ast = parse($expr);
    return compile( $ast, $self );
}

=method index

Takes a tree node and returns a L<TPath::Index> object that
L<TPath::Expression> objects can use to cache information about
the tree rooted at the given node.

=cut

sub index {
    my ( $self, $node ) = @_;

    # TODO construct a proper index here
}

sub _kids {
    my ( $self, $n, $i ) = @_;
    my @children = $self->children( $n, $i );
    return @children unless $self->count_tests;
    grep {
        for my $t ( $self->tests ) {
            return () if $t->( $_, $i );
        }
        $_;
    } @children;
}

sub _axis_ancestor { goto &_ancestors }

sub _axis_ancestor_or_self {
    my ( $self, $n, $t, $i ) = @_;
    my @nodes = $self->_ancestors( $n, $t, $i );
    push @nodes, $n if $t->passes( $n, $i );
    return @nodes;
}

sub _axis_child { goto &_children }

sub _axis_descendant { goto &_descendants }

sub _axis_descendant_or_self {
    my ( $self, $n, $t, $i ) = @_;
    my @descendants = $self->_descendants( $n, $t, $i );
    push @descendants, $n if $t->passes( $n, $i );
    return @descendants;
}

sub _axis_following { goto &_following }

sub _axis_following_sibling { goto &_following_siblings }

sub _axis_leaf { goto _&leaves }

sub _axis_parent {
    my ( $self, $n, $t, $i ) = @_;
    my $parent = $self->parent( $n, $i );
    return $t->passes( $parent, $i ) ? $parent : ();
}

sub _axis_preceding { goto &_preceding }

sub _axis_preceding_sibling { goto &_preceding_siblings }

sub _axis_self {
    my ( $self, $n, $t, $i ) = @_;
    return $t->passes( $n, $i ) ? $n : ();
}

sub _axis_sibling { goto &_siblings }

sub _axis_sibling_or_self { goto &_siblings_or_self }

sub _siblings_or_self {
    my ( $self, $n, $t, $i ) = @_;
    return $n if $i->is_root($n) && $t->passes( $n, $i );
    return
      grep { $t->passes( $_, $i ) } $self->_kids( $self->parent( $n, $i ), $i );
}

sub _siblings {
    my ( $self, $n, $t, $i ) = @_;
    my @siblings = $self->_untested_siblings( $self->parent( $n, $i ), $i );
    return grep { $t->passes( $_, $i ) } $self->_untested_siblings( $n, $i );
}

sub _untested_siblings {
    my ( $self, $n, $i ) = @_;
    return () if $self->is_root( $n, undef, $i );
    return grep { $_ != $n } $self->_kids( $self->parent( $n, $i ), $i );
}

sub _preceding {
    my ( $self, $n, $t, $i ) = @_;
    return () if $self->is_root( $n, undef, $i );
    my @preceding;
    state $tt // = TPath::Test::Node::True->new;
    my @ancestors = $self->_ancestors( $n, $tt, $i );
    for my $a ( @ancestors[ 1 .. $#ancestors ] ) {
        for my $p ( $self->_preceding_siblings( $a, $tt, $i ) ) {
            push @preceding, $self->descendants( $p, $t, $i );
            push @preceding, $p if $t->passes( $p, $i );
        }
    }
    for my $p ( $self->_preceding_siblings( $n, $tt, $i ) ) {
        push @preceding, $self->_descendants( $p, $t, $i );
        push @preceding, $p if $t->passes( $p, $i );
    }
    return @preceding;
}

sub _preceding_siblings {
    my ( $self, $n, $t, $i ) = @_;
    return () if $self->is_root( $n, undef, $i );
    my @siblings = $self->_kids( $self->parent( $n, $i ), $i );
    return () if @siblings == 1;
    my @preceding_siblings;
    for my $s (@siblings) {
        last if $s == $n;
        push @preceding_siblings, $s if $t->passes( $s, $i );
    }
    return @preceding_siblings;
}

sub _leaves {
    my ( $self, $n, $t, $i ) = @_;
    my @children = $self->_kids( $n, $i );
    return $t->passes( $n, $i ) ? $n : ();
    unless @children;
    my @leaves;
    push @leaves, $self->_leaves( $_, $t, $i ) for @children;
    return @leaves;
}

sub _following {
    my ( $self, $n, $t, $i ) = @_;
    return () if $self->is_root( $n, undef, $i );
    my @following;
    state $tt // = TPath::Test::Node::True->new;
    my @ancestors = $self->_ancestors( $n, $tt, $i );
    for my $a ( @ancestors[ 1 .. $#ancestors ] ) {
        for my $p ( $self->_following_siblings( $a, $tt, $i ) ) {
            push @following, $self->_descendants( $p, $t, $i );
            push @following, $p if $t->passes( $p, $i );
        }
    }
    for my $p ( $self->_following_siblings( $n, $tt, $i ) ) {
        push @following, $self->_descendants( $p, $t, $i );
        push @following, $p if $t->passes( $p, $i );
    }
    return @following;
}

sub _following_siblings {
    my ( $self, $n, $t, $i ) = @_;
    return () if $self->is_root( $n, undef, $i );
    my @siblings = $self->_kids( $self->parent( $n, $i ), $i );
    return () if @siblings == 1;
    my ( @following_siblings, $add );
    for my $s (@siblings) {
        if ($add) {
            push @following_siblings, $s if $t->passes( $s, $i );
        }
        else {
            $add = $n == $s;
        }
    }
    return @following_siblings;
}

sub _descendants {
    my ( $self, $n, $t, $i ) = @_;
    my @children = $self->_kids( $n, $i );
    return () unless @children;
    my @descendants;
    for my $c (@children) {
        push @descendants, $self->_descendants( $c, $t, $i )
          unless $self->is_leaf( $c, undef, $i );
        push @descendants, $t if $t->passes( $c, $i );
    }
    return @descendants;
}

=method is_leaf

Expects a node, a collection, and an index.

Returns whether the context node is a leaf. Override this with something more
efficient where available. E.g., where the node provides an C<is_leaf> method,

  sub is_leaf { $_[1]->is_leaf }

=cut

sub is_leaf {
    my ( $self, $n, $c, $i ) = @_;
}

=method is_root

Expects a node, a collection, and an index.

Returns whether the context node is the root. Delegates to index.

Override this with something more efficient where available. E.g., where the 
node provides an C<is_root> method,

  sub is_root { $_[1]->is_root }

=cut

sub is_root {
    my ( $self, $n, $c, $i ) = @_;
    $i->is_root($n);
}

sub _ancestors {
    my ( $self, $n, $t, $i ) = @_;
    my @nodes;
    while ( !$self->is_root( $n, undef, $i ) ) {
        my $parent = $self->parent( $n, $i );
        unshift @nodes, $parent if $t->passes( $parent, $i );
        $n = $parent;
    }
    return @nodes;
}

sub _children {
    my ( $self, $n, $t, $i ) = @_;
    my @children = $self->_kids( $n, $i );
    return () unless @children;
    grep { $t->passes( $_, $i ) ? $_ : () } @children;
}

1;
