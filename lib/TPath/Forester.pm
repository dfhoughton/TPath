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
      # my ($self, $node, $index, $collection, @args) = @_;
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

=head2 Why "Forester"

Foresters are people who can tell you about trees. A class with the role C<TPath::Forester>
can also tell you about trees. I think know "arborist" sounds better, but I don't feel like
refactoring everything to use a new name.

=cut

use v5.10;
use Scalar::Util qw(refaddr);
use Moose::Role;

use TPath::Compiler qw(compile);
use TPath::Grammar qw(parse);
use TPath::Index;
use TPath::StderrLog;
use TPath::Test::Node::True;

=head1 ROLES

L<TPath::Attributes::Standard>, L<TPath::TypeCheck>

=cut

with qw(TPath::Attributes::Standard TPath::TypeCheck);

=head1 REQUIRED METHODS

=head2 children

Expects a node and an index. Returns the children of the node as a list.

=head2 tag

Expects a node and returns the value selectors are matched against, or C<undef> if the node
has no tag.

If your node type cannot be so easily mapped to a particular tag, you may want to override the
C<has_tag> and C<matches_tag> methods and supply a no-op method for C<tag>.

=cut

requires qw(children tag);

=attr log_stream

A L<TPath::LogStream> required by the C<@log> attribute. By default it is L<TPath::StderrLog>. This attribute
is required by the C<@log> attribute from L<TPath::Attributes::Standard>.

=cut

has log_stream => (
    is      => 'rw',
    isa     => 'TPath::LogStream',
    default => sub { TPath::StderrLog->new }
);

=method add_test, has_tests, clear_tests

Add a code ref that will be used to test whether a node is ignorable. The
return value of this code will be treated as a boolean value. If it is true,
the node, and all its children, will be passed over as possible items to return
from a select.

Example test:

  $f->add_test(sub {
      my ($forester, $node, $index) = @_;
      return $forester->has_tag('foo');
  });

Every test will receive the forester itself, the node, and the index as arguments. This example test
will cause the forester C<$f> to ignore C<foo> nodes.

This method has the companion methods C<has_tests> and C<clear_tests>. The former says
whether the list is empty and the latter clears it.

=cut

has _tests => (
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_test    => 'push',
        has_tests   => 'count',
        clear_tests => 'clear',
    },
    auto_deref => 1
);

# map from attribute names to their implementations
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
                if ( $annotation =~ /^Attr\((.*)\)$/ ) {
                    $attributes{$1} = $method->body;
                }
                else {
                    confess "malformed annotation $annotation on method "
                      . $method->name;
                }
            }
        }
    }
    return \%attributes;
}

=method add_attribute

Expects a name, a code reference, and possibly options. Adds the attribute to the forester.

If the attribute name is already in use, the method will croak unless you specify that this
attribute should override the already named attribute. E.g.,

  $f->add_attribute( 'foo', sub { ... }, -override => 1 );

If you specify the attribute as overriding and the name is *not* already in use, the method
will carp. You can use the C<-force> option to skip all this checking and just add the
attribute.

Note that the code reference will receive the forester, a node, an index, a collection of nodes, and
optionally any additional arguments. B<If you want the attribute to evaluate as undefined for
a particular node, it must return C<undef> for this node.>

=cut

sub add_attribute {
    my ( $self, $name, $attr, %options ) = @_;
    die 'attributes must have non-empty names' unless $name;
    die "attribute $name but be a code reference" unless ref $attr eq 'CODE';
    if ( $options{-force} ) {
        $self->_attributes->{$name} = $attr;
    }
    elsif ( $options{-override} ) {
        carp("override used by attribute $name does not exist")
          unless exists $self->_attributes->{$name};
        $self->_attributes->{$name} = $attr;
    }
    else {
        croak("attribute $name already exists")
          if exists $self->_attributes->{$name};
        $self->_attributes->{$name} = $attr;
    }
}

=method attribute

Expects a L<TPath::Context>, an attribute name, and an optional parameter list. Returns
the value of the attribute in that context.

=cut

sub attribute {
    my ( $self, $ctx, $aname, @params ) = @_;
    $self->_attributes->{$aname}->( $self, $ctx, @params );
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
    TPath::Index->new(
        f         => $self,
        root      => $node,
        node_type => $self->node_type
    );
}

=method parent

Expects a L<TPath::Context> and returns the parent of the context node according to the index.
If your nodes know their own parents, you probably want to override this method. See also
L<TPath::Index>.

=cut

sub parent {
    my ( $self, $original, $ctx ) = @_;
    my $p = $ctx->i->parent( $ctx->n );
    return undef unless $p;
    return $original->bud($p);
}

=method id

Expects a node. Returns id of node, if any. By default this method always returns undef.
Override if your node has some defined notion of id.

=cut

sub id { }

sub _kids {
    my ( $self, $original, $ctx ) = @_;
    my $i = $ctx->i;
    my @children = $self->children( $ctx->n, $i );
    return map { $original->bud($_) } @children unless $self->has_tests;
    map { $original->bud($_) } grep {
        my $good = 1;
        for my $t ( $self->_tests ) {
            $good &= $t->( $self, $_, $i );
            last unless $good;
        }
        $good;
    } @children;
}

sub _decontextualized_kids {
    my ( $self, $n, $i ) = @_;
    my @children = $self->children( $n, $i );
    return @children unless $self->has_tests;
    grep {
        my $good = 1;
        for my $t ( $self->_tests ) {
            $good &= $t->( $self, $_, $i );
            last unless $good;
        }
        $good;
    } @children;
}

sub axis_ancestor {
    my ( $self, $ctx, $t ) = @_;
    $self->_ancestors( $ctx, $ctx, $t );
}

sub axis_ancestor_or_self {
    my ( $self, $ctx, $t ) = @_;
    my @nodes = $self->_ancestors( $ctx, $ctx, $t );
    push @nodes, $ctx if $t->passes($ctx);
    return @nodes;
}

sub axis_child {
    my ( $self, $ctx, $t ) = @_;
    $self->_children( $ctx, $ctx, $t );
}

sub axis_descendant {
    my ( $self, $ctx, $t ) = @_;
    $self->_descendants( $ctx, $ctx, $t );
}

sub axis_descendant_or_self {
    my ( $self, $ctx, $t ) = @_;
    my @descendants = $self->_descendants( $ctx, $ctx, $t );
    push @descendants, $ctx if $t->passes($ctx);
    return @descendants;
}

sub axis_following {
    my ( $self, $ctx, $t ) = @_;
    $self->_following( $ctx, $ctx, $t );
}

sub axis_following_sibling {
    my ( $self, $ctx, $t ) = @_;
    $self->_following_siblings( $ctx, $ctx, $t );
}

sub axis_leaf { my ( $self, $ctx, $t ) = @_; $self->_leaves( $ctx, $ctx, $t ) }

sub axis_parent {
    my ( $self, $ctx, $t ) = @_;
    my $parent = $self->parent( $ctx, $ctx );
    return () unless $parent;
    return $t->passes($parent) ? $parent : ();
}

sub axis_preceding {
    my ( $self, $ctx, $t ) = @_;
    $self->_preceding( $ctx, $ctx, $t );
}

sub axis_previous {
    my ( $self, $ctx, $t ) = @_;
    my @previous;
    while ( my $previous = $ctx->previous ) {
        push @previous, $previous if $t->passes($previous);
        $ctx = $previous;
    }
    return @previous;
}

sub axis_preceding_sibling {
    my ( $self, $ctx, $t ) = @_;
    $self->_preceding_siblings( $ctx, $ctx, $t );
}

sub axis_self {
    my ( $self, $ctx, $t ) = @_;
    return $t->passes($ctx) ? $ctx->bud( $ctx->n ) : ();
}

sub axis_sibling {
    my ( $self, $ctx, $t ) = @_;
    $self->_siblings( $ctx, $ctx, $t );
}

sub axis_sibling_or_self {
    my ( $self, $ctx, $t ) = @_;
    $self->_siblings_or_self( $ctx, $ctx, $t );
}

sub closest {
    my ( $self, $ctx, $t, $first ) = @_;
    return $ctx if !$first && $t->passes($ctx);
    my @children = $self->_kids( $ctx, $ctx );
    my @closest;
    for my $c (@children) {
        push @closest, $self->closest( $c, $t, 0 );
    }
    return @closest;
}

sub _siblings_or_self {
    my ( $self, $original, $ctx, $t ) = @_;
    grep { $t->passes($_) }
      $self->_kids( $original, $self->parent( $original, $ctx ) );
}

sub _siblings {
    my ( $self, $original, $ctx, $t ) = @_;
    my @siblings =
      $self->_untested_siblings( $original, $self->parent( $original, $ctx ) );
    grep { $t->passes($_) } @siblings;
}

sub _untested_siblings {
    my ( $self, $original, $ctx ) = @_;
    return () if $self->is_root($ctx);
    my $ra = refaddr $ctx->n;
    grep { refaddr $_->n ne $ra }
      $self->_kids( $original, $self->parent( $original, $ctx ) );
}

sub _preceding {
    my ( $self, $original, $ctx, $t ) = @_;
    return () if $self->is_root($ctx);
    my @preceding;
    state $tt = TPath::Test::Node::True->new;
    my @ancestors = $self->_ancestors( $original, $ctx, $tt );
    for my $a ( @ancestors[ 1 .. $#ancestors ] ) {
        for my $p ( $self->_preceding_siblings( $original, $a, $tt ) ) {
            push @preceding, $self->_descendants( $original, $p, $t );
            push @preceding, $p if $t->passes($p);
        }
    }
    for my $p ( $self->_preceding_siblings( $original, $ctx, $tt ) ) {
        push @preceding, $self->_descendants( $original, $p, $t );
        push @preceding, $p if $t->passes($p);
    }
    return @preceding;
}

sub _preceding_siblings {
    my ( $self, $original, $ctx, $t ) = @_;
    return () if $self->is_root($ctx);
    my @siblings = $self->_kids( $original, $self->parent( $original, $ctx ) );
    return () if @siblings == 1;
    my @preceding_siblings;
    my $ra = refaddr $ctx->n;
    for my $s (@siblings) {
        last if refaddr $s->n == $ra;
        push @preceding_siblings, $s if $t->passes($s);
    }
    return @preceding_siblings;
}

sub _leaves {
    my ( $self, $original, $ctx, $t ) = @_;
    my @children = $self->_kids( $original, $ctx );
    return $t->passes($ctx) ? $ctx : () unless @children;
    my @leaves;
    push @leaves, $self->_leaves( $original, $_, $t ) for @children;
    return @leaves;
}

sub _following {
    my ( $self, $original, $ctx, $t ) = @_;
    return () if $self->is_root($ctx);
    my @following;
    state $tt = TPath::Test::Node::True->new;
    my @ancestors = $self->_ancestors( $original, $ctx, $tt );
    for my $a ( @ancestors[ 1 .. $#ancestors ] ) {
        for my $p ( $self->_following_siblings( $original, $a, $tt ) ) {
            push @following, $self->_descendants( $original, $p, $t );
            push @following, $p if $t->passes($p);
        }
    }
    for my $p ( $self->_following_siblings( $original, $ctx, $tt ) ) {
        push @following, $self->_descendants( $original, $p, $t );
        push @following, $p if $t->passes($p);
    }
    return @following;
}

sub _following_siblings {
    my ( $self, $original, $ctx, $t ) = @_;
    return () if $self->is_root($ctx);
    my @siblings = $self->_kids( $original, $self->parent( $original, $ctx ) );
    return () if @siblings == 1;
    my ( @following_siblings, $add );
    my $ra = refaddr $ctx->n;
    for my $s (@siblings) {
        if ($add) {
            push @following_siblings, $s if $t->passes($s);
        }
        else {
            $add = $ra == refaddr $s->n;
        }
    }
    return @following_siblings;
}

sub _descendants {
    my ( $self, $original, $ctx, $t ) = @_;
    my @children = $self->_kids( $original, $ctx );
    return () unless @children;
    my @descendants;
    for my $c (@children) {
        push @descendants, $self->_descendants( $original, $c, $t );
        push @descendants, $c if $t->passes($c);
    }
    return @descendants;
}

=method is_leaf

Expects a node, and an index.

Returns whether the context node is a leaf. Override this with something more
efficient where available. E.g., where the node provides an C<is_leaf> method,

  sub is_leaf { $_[1]->is_leaf }

=cut

sub is_leaf {
    my ( $self, $ctx ) = @_;
    my @children = $self->_kids( $ctx, $ctx );
    return !@children;
}

=method is_root

Expects a node and an index.

Returns whether the context node is the root. Delegates to index.

Override this with something more efficient where available. E.g., where the 
node provides an C<is_root> method,

  sub is_root { $_[1]->is_root }

=cut

sub is_root {
    my ( $self, $ctx ) = @_;
    $ctx->i->is_root( $ctx->n );
}

sub _ancestors {
    my ( $self, $original, $ctx, $t ) = @_;
    my @nodes;
    while ( !$self->is_root($ctx) ) {
        my $parent = $self->parent( $original, $ctx );
        unshift @nodes, $parent if $t->passes($parent);
        $ctx = $parent;
    }
    return @nodes;
}

sub _children {
    my ( $self, $original, $ctx, $t ) = @_;
    my @children = $self->_kids( $original, $ctx );
    return () unless @children;
    grep { $t->passes($_) ? $_ : () } @children;
}

=method has_tag

Expects a node and a string. Returns whether the node, in whatever sense is appropriate
to this sort of node, "has" the string as a tag. See the required C<tag> method.
=cut

sub has_tag {
    my ( $self, $n, $tag ) = @_;
    my $t = $self->tag($n);
    return undef unless defined $t;
    $t eq $tag;
}

=method matches_tag

Expects a node and a compiled regex. Returns whether the node, in whatever sense is appropriate
to this sort of node, has a tag that matches the regex. See the required C<tag> method.

=cut

sub matches_tag {
    my ( $self, $n, $rx ) = @_;
    my $t = $self->tag($n);
    return undef unless defined $t;
    $t =~ $rx;
}

=method wrap

Expects a node and possibly an options hash. Returns a node of the type understood by the forester.

If your forester must coerce things into a tree of the right type, override this method, which otherwise
just passes through its second argument.

Note, if you do need to override the default wrap, you'll have to jump through a few Moose hoops. The
basic pattern is

  ...
  use Moose;
  ...
  with 'TPath::Forester' => { -excludes => 'wrap' };
  ...

  {
      no warnings 'redefine';
      sub wrap {
          my ($self, $node, %opts) = @_;
          return $node if blessed $node and $node->isa('MyNode');
          # coerce
          ...
      }
  }

See L<TPath::Forester::Ref> for an example.

=cut

sub wrap { return $_[1] }

1;
