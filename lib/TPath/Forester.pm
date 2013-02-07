package TPath::Forester;

# ABSTRACT: a generator of TPath expressions for a particular class of nodes

=head1 SYNOPSIS

  # define our own attributes
  {
    package MyAttributes;
    use Moose::Role;
    use MooseX::MethodAttributes::Role;
   
    sub baz :Attr {
      # the canonical order of arguments, none of which we need
      # my ($self, $node, $collection, $index, @args) = @_;
      'baz';
    }
  }

  # we apply the TPath::Forester role to a class
  {
    package MyForester;
    use Moose;                                      # for simplicity we omit removing Moose droppings, etc.
    with qw(TPath::Forester MyAttributes);

    # define abstract methods
    sub children   { $_[1]->children }              # our nodes know their children
    sub parent     { $_[1]->parent }                # our nodes know their parent
    sub has_tag    {                                # our nodes have a tag attribute which is
       my ($self, $node, $tag) = @_;                # their only tag
       $node->tag eq $tag;
    }
    sub matches_tag { 
       my ($self, $node, $re) = @_;
       $node->tag =~ $re;
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
use TPath::Attributes::Standard;

with 'TPath::Attributes::Standard';

=head1 REQUIRED METHODS

=over 8

=item B<children>

Expects a node and an index. Returns the children of the node as a list.

=item B<has_tag>

Expects a node and a string. Returns whether the node, in whatever sense is appropriate
to this sort of node, "has" the string as a tag.

=item B<matches_tag>

Expects a node and a compiled regex. Returns whether the node, in whatever sense is appropriate
to this sort of node, has a tag that matches the regex.

=item B<parent>

Expects a node and an index. Returns the parent of the node.

=back

=cut

requires qw(children has_tag matches_tag parent);

has log_stream => (
    is      => 'rw',
    isa     => 'TPath::LogStream',
    default => sub { TPath::StderrLog->new }
);

=method add_test

Add a code ref that will be used to test whether a node is ignorable. The
return value of this code will be treated as a boolean value. If it is true,
the node, and all its children, will be passed over as possible items to return
from a select.

This method has companion methods C<tests>, C<count_tests>, and C<clear_tests>. The first returns
the tests as a list. The last empties the list. C<count_tests> returns how many tests have
been defined.

=cut

has _tests => (
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    default => sub { [] },
    handles => {
        add_test    => 'push',
        tests       => 'elements',
        clear_tests => 'clear',
        count_tests => 'count'
    }
);

=method attributes (regard as protected)

A map from attribute names to code refs. These will be only those
subs marked with the C<Attr> attribute. If the attribute name differs from
the sub name, the appropriate alias must be supplied inside parentheses after
'Attr'. E.g.,

  sub foo :Attr(baz) { 'bar' }

Perl requires that the content between the braces not contain colons or parentheses.
C<TPath::Forester> uses L<URI::Escape> to parse this content, so you can get around this
restriction by URI escaping the offending characters:

=over 4

=item :

%3A

=item (

%28

=item )

%29

=item %

%25

=back

=cut

has attributes => (
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
}

sub kids {
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

1;
