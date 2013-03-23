package TPath;

# ABSTRACT: general purpose path languages for trees

1;

__END__

=head1 SYNOPSIS

  # we define our trees
  package MyTree;
  
  use overload '""' => sub {
      my $self     = shift;
      my $tag      = $self->{tag};
      my @children = @{ $self->{children} };
      return "<$tag/>" unless @children;
      local $" = '';
      "<$tag>@children</$tag>";
  };
  
  sub new {
      my ( $class, %opts ) = @_;
      die 'tag required' unless $opts{tag};
      bless { tag => $opts{tag}, children => $opts{children} // [] }, $class;
  }
  
  sub add {
      my ( $self, @children ) = @_;
      push @{ $self->{children} }, $_ for @children;
  }
  
  # teach TPath::Forester how to get the information it needs
  package MyForester;
  use Moose;
  use MooseX::MethodAttributes;    # needed for @tag attribute below
  with 'TPath::Forester';
  
  # implement required methods
  
  sub children {
      my ( $self, $n ) = @_;
      @{ $n->{children} };
  }
  
  sub tag : Attr {                 # also an attribute!
      my ( $self, $n ) = @_;
      $n->{tag};
  }
  
  package main;
  
  # make the tree
  #      a
  #     /|\
  #    / | \
  #   b  c  \
  #  /\  |   d
  #  e f |  /|\
  #      h / | \
  #     /| i j  \
  #    l | | |\  \
  #      m n o p  \
  #     /|    /|\  \
  #    s t   u v w  k
  #                / \
  #               q   r
  #                  / \
  #                 x   y
  #                     |
  #                     z
  my %nodes = map { $_ => MyTree->new( tag => $_ ) } 'a' .. 'z';
  $nodes{a}->add($_) for @nodes{qw(b c d)};
  $nodes{b}->add($_) for @nodes{qw(e f)};
  $nodes{c}->add( $nodes{h} );
  $nodes{d}->add($_) for @nodes{qw(i j k)};
  $nodes{h}->add($_) for @nodes{qw(l m)};
  $nodes{i}->add( $nodes{n} );
  $nodes{j}->add($_) for @nodes{qw(o p)};
  $nodes{k}->add($_) for @nodes{qw(q r)};
  $nodes{m}->add($_) for @nodes{qw(s t)};
  $nodes{p}->add($_) for @nodes{qw(u v w)};
  $nodes{r}->add($_) for @nodes{qw(x y)};
  $nodes{y}->add( $nodes{z} );
  my $root = $nodes{a};
  
  # make our forester
  my $rhood = MyForester->new;
  
  # index our tree (not necessary, but efficient)
  my $index = $rhood->index($root);
  
  # try out some paths
  my @nodes = $rhood->path('//r')->select( $root, $index );
  print scalar @nodes, "\n";    # 1
  print $nodes[0], "\n";        # <r><x/><y><z/></y></r>
  print $_
    for $rhood->path('leaf::*[@tag > "o"]')->select( $root, $index )
    ;                           # <s/><t/><u/><v/><w/><q/><x/><z/>
  print "\n";
  print $_->{tag}
    for $rhood->path('//*[@tsize = 3]')->select( $root, $index );    # bm
  print "\n";
  @nodes = $rhood->path('/>~[bh-z]~')->select( $root, $index );
  print $_->{tag} for @nodes;                                        # bhijk
  print "\n";
  
  # we can map nodes back to their parents
  @nodes = $rhood->path('//*[parent::~[adr]~]')->select( $root, $index );
  print $_->{tag} for @nodes;                                        # bcijxykd
  print "\n";

=head1 DESCRIPTION

TPath provides an XPath-like language for arbitrary trees. You implement a minimum of two
methods -- C<children> and C<tag> -- and then you can explore your trees via
concise, declarative paths.

In TPath, "attributes" are node attributes of any sort and are implemented as methods that 
return these attributes, or C<undef> if the attribute is undefined for the node.

The object in which the two required methods are implemented is a "forester" (L<TPath::Forester>),
something that understands your trees. In general to use C<TPath> you instantiate a forester and
then call the forester's methods.

Forester objects make use of an index (L<TPath::Index>), which caches information not present in, or
not cheaply from, the nodes themselves. If no index is explicitly provided it is created, but one
can gain some efficiency by reusing an index when select paths from a tree. One can use a forester's
C<index> method to produce a C<TPath::Index>.

The paths themselves are compiled into reusable L<TPath::Expression> objects that can be applied 
to multiple trees. One use's a forester's C<path> method to produce a C<TPath::Expression>.

=head1 ALGORITHM

TPath works by representing an expression as a pipeline of selectors and filters. Each pair of a
selector and some set of filters is called a "step". At each step one has a set of context nodes.
One applies the selectors to each context node, returning a candidate node set, and then one passes
these candidates through the filtering predicates. The remainder becomes the context node set
for the next step. If this is the last step, the surviving candidates are the nodes selected by the
expression. A node will only occur once among those returned and the order of their return will be
the order of their discovery. Search is depth-first post-ordered -- children returned before parents.

=head1 SYNTAX

=head2 Sub-Paths

A tpath expression has one or more sub-paths.

=over 2

=item C<B<//a/b>|preceding::d/*>

=item C<//a/b|B<preceding::d/*>>

=back

Sub-paths are separated by the pipe symbol C<|> and optional space.

The nodes selected by a path is the union of the nodes selected by each sub-path in the order of
their discovery. The search is left-to-right and depth first. If a node and its descendants are both selected, the
descendants will be listed first.

=head2 Steps

=over 2

=item C<B<//a>/b[0]/E<gt>c[@d]>

=item C<//aB</b[0]>/E<gt>c[@d]>

=item C<//a/b[0]B</E<gt>c[@d]>>

=back

Each step consists of a separator (optional on the first step), a tag selector, and optionally some
number of predicates.

=head2 Separators

=over 2

=item C<a/b/c/E<gt>d>

=item C<B</>aB</>b//c/E<gt>d>

=item C<B<//>a/bB<//>c/E<gt>d>

=item C<B</E<gt>>a/b//cB</E<gt>>d>

=back

=head3 null separator

=over 2

=item C<a/b/c/E<gt>d>

=back
  
The null separator is simply the absence of a separator and can only occur before the first step. 
It means "relative to the context node". Thus is it essentially the same as the file path formalism,
where C</a> means the file C<a> in the root directory and C<a> means the file C<a> in the current directory.

=head3 /

=over 2

=item C<B</>aB</>b//c/E<gt>d>

=back

The single slash separator means "search among the context node's children", or if it precedes
the first step it means that the context node is the root node.

=head3 // select among descendants

=over 2

=item C<B<//>a/bB<//>c/E<gt>d>

=back
  
The double slash separator means "search among the descendants of the context node" or, if the
context node is the root, "search among the root node and its descendants".

=head3 /> select closest

=over 2

=item C<B</E<gt>>a/b//cB</E<gt>>d>

=back

The C</E<gt>> separator means "search among the descendants of the context node (or the context node
and its descendants if the context node is root), but omit from consideration any node dominated by
a node matching the selector". Written out like this this may be confusing, but it is a surprisingly
useful separator. Consider the following tree

         a
        / \
       b   a
       |   | \
       a   b  a
       |      |
       b      b

The expression C</E<gt>b> when applied to the root node will select all the C<b> nodes B<except> the
leftmost leaf C<b>, which is screened from the root by its grandparent C<b> node. That is, going down
any path from the context node C</E<gt>b> will match the first node it finds matching the selector --
the matching node closest to the context node.

=head2 Selectors

Selectors select a candidate set for later filtering by predicates.

=head3 literal

=over 2

=item C<B<a>>

=back

A literal selector selects the nodes whose tag matches, in a tree-appropriate sense of "match",
a literal expression.

Any string may be used to represent a literal selector, but certain characters may have to be
escaped with a backslash. The expectation is that the literal with begin with a word character, _,
or C<$> and any subsequent character is either one of these characters, a number character or 
a hyphen or colon followed by one of these or number character. The escape character, as usual, is a
backslash. Any unexpected character must be escaped. So

=over 2

=item C<a\\b>

=back

represents the literal C<a\b>.

=head3 ~a~ regex

=over 2

=item C<~a~>

=back

A regex selector selects the nodes whose tag matches a regular expression delimited by tildes. Within
the regular expression a tilde must be escaped, of course. A tilde within a regular expression is
represented as a pair of tildes. The backslash, on the other hand, behaves as it normally does within
a regular expression.

=head3 @a attribute

Any attribute may be used as a selector so long as it is preceded by something other than
the null separator -- in other words, C<@> cannot be the first character in a path. This is because 
attributes may take arguments and among other things these arguments can be both expressions and 
other attributes. If C<@foo> were a legitimate path expression it would be ambiguous how to compile 
C<@bar(@foo)>. Is the argument an attribute or a path with an attribute selector. You can produce
the effect of an attribute selector with the null separator, however, in two ways

=over 2

=item C<child::@foo>

=item C<./@foo>

=back

the second of these will be normalized in parsing to precisely what one would expect with a C<@foo>
path.

=head3 complement selectors

The C<^> character before a literal, regex, or attribute selector will convert it into an attribute selector.

=over 2

=item C<//B<^>foo>

=item C<//B<^>~foo~>

=item C<//B<^>@foo>

=back

Complement selectors select nodes not selected by the unmodified selector; C<//^foo> will select any node
without the C<foo> tag, and so forth.

=head3 * wildcard

The wildcard selector selects all the nodes an the relevant axis. The default axis is C<child>, so
C<//b/*> will select all the children of C<b> nodes.

=head2 Axes

To illustrate the nodes on various axes I will using the following tree, showing which nodes
are selected from the tree relative the the C<c> node. Selected nodes will be in capital letters.

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=over 8

=item ancestor

  //c/ancestor::*

         ROOT
          |
          A
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item ancestor-or-self

         ROOT
          |
          A
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     C     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item child

  //c/child::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g H I J l m n
    |     |     |
    o     p     q

=item descendant

  //c/descendant::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g H I J l m n
    |     |     |
    o     P     q

=item descendant-or-self

  //c/descendant-or-self::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     C     d
   /|\   /|\   /|\
  e f g H I J l m n
    |     |     |
    o     P     q

=item following

  //c/following::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     D
   /|\   /|\   /|\
  e f g h i j L M N
    |     |     |
    o     p     Q

=item following-sibling

  //c/following-sibling::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     D
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item leaf

  //c/leaf::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g H i J l m n
    |     |     |
    o     P     q

=item parent

  //c/parent::*

         root
          |
          A
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     c     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item preceding

  //c/preceding::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    B     c     d
   /|\   /|\   /|\
  E F G h i j l m n
    |     |     |
    O     p     q

=item preceding-sibling

  //c/preceding-sibling::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    B     c     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item self

  //c/self::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    b     C     d
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item sibling

  //c/sibling::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    B     c     D
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=item sibling-or-self

  //c/sibling-or-self::*

         root
          |
          a
         /|\
        / | \
       /  |  \
      /   |   \
     /    |    \
    B     C     D
   /|\   /|\   /|\
  e f g h i j l m n
    |     |     |
    o     p     q

=back

=head2 Predicates

=over 2

=item C<//a/bB<[0]>/E<gt>c[@d][@e E<lt> 'string'][@f or @g]>

=item C<//a/b[0]/E<gt>B<c[@d]>[@e E<lt> 'string'][@f or @g]>

=item C<//a/b[0]/E<gt>c[@d]B<[@e E<lt> 'string']>[@f or @g]>

=item C<//a/b[0]/E<gt>c[@d][@e E<lt> 'string']B<[@f or @g]>>

=back

Predicates are the sub-expressions in square brackets after selectors. They represents
tests that filter the candidate nodes selected by the selectors. 

There may be space inside the square brackets.

=head2 Index Predicates

  //foo/bar[0]

An index predicate simply selects the indexed item out of a list of candidates. The first
index is 0, unlike in XML, so the expression above selects the first bar under every foo.

The index rules are the same as those for Perl arrays: 0 is the first item; negative indices
count from the end, so -1 retrieves the last item.

=head2 Attributes

  //foo[@bar]
  //foo[@bar(1, 'string', path, @attribute, @attribute = 'test')]

Attributes identify callbacks that evaluate the context node to see whether the respective
attribute is defined for it. If the callback returns a defined value, the predicate is true
and the candidate is accepted; otherwise, it is rejected.

As the second example above demonstrates, attributes may take arguments and these arguments
may be numbers, strings, paths, other attributes, or attribute tests (see below). Paths are
evaluated relative to the candidate node being tested, as are attributes and attribute tests.
A path arguments represents the nodes selected by this path relative to the candidate node.

Attribute parameters are enclosed within parentheses. Within these parentheses, they are
delimited by commas. Space is optional around parameters.

For the standard attribute set available to all expressions, see L<TPath::Attributes::Standard>.
For the extended set that can be composed in, see L<TPath::Attributes::Extended>. There are
various ways one can add bespoke attributes but the easiest is to add them to an individual
forester via the C<add_attribute> method:

  my $forester = MyForester->new;
  $forester->add_attribute( 'foo' => sub {
     my ( $self, $node, $index, $collection, @params) = @_;
     ...
  });

TODO: explain other means to define new attributes.

=head2 Attribute Tests

Attribute tests compare attributes to literals, numbers, or other attributes

TODO: complete this section.

=head2 Boolean Predicates

Boolean predicates combine various terms -- attributes, attribute tests, or tpath expressions --
via boolean operators:

=over 8

=item C<!> or C<not>

True iff the attribute is undefined, the attribute test returns false, the expression returns
no nodes, or the boolean expression is false.

=item C<&> or C<and>

True iff all conjoined operands are true.

=item C<||> or C<or>

True iff any of the conjoined operands is true.

Note that boolean or is two pipe characters. This is to disambiguate the path expression
C<a|b> from the boolean expression C<a||b>.

=item C<^> or C<xor>

True B<if one and only one of the conjoined operands is true>. The expression

  @a ^ @b

Behaves like ordinary exclusive or. But if more than two operands are conjoined
this way, the entire expression is a uniqueness test.

=item C<( ... )>

Groups the contained boolean operations. True iff they evaluate to true.

=back

The normal precedence rules of logical operators applies to these:

  () < ! < & < ^ < ||

Space is required around operators only where necessary to prevent their being
interpreted as part of a path or attribute.

=head2 Special Selectors

There are three special selectors B<that cannot occur with predicates>.

=head3 . : Select Self

This is an abbreviation for C<self::*>.

=head3 .. : Select Parent

This is an abbreviation for C<parent::*>.

=head3 id(foo) : Select By Index

This selector selects the node, if any, with the given id. This same node can also be selected
by C<//*[@id = 'foo']> but this is much less efficient.

=head2 Hiding Nodes

In some cases there may be nodes -- spaces, comments, hidden directories and files -- that you
want your expressions to treat as invisible. To do this you add invisibility tests to the forester
object that generates expressions.

  my $forester = MyForester->new;
  $forester->add_test( sub {
     my ($forester, $node, $index) = @_;
     ... # return true if the node should be invisible
  });

One can put this in the forester's C<BUILD> method to make them invisible to all instances of the
class.

=head1 HISTORY

I wrote TPath initially in Java (L<http://dfhoughton.org/treepath/>) because I wanted a more 
convenient way to select nodes from parse trees. I've re-written it in Perl because I figured
it might be handy and why not?

=head1 ACKNOWLEDGEMENTS

Thanks to Damian Conway for L<Regexp::Grammars>, which makes it pleasant to write complicated
parsers, and the Moose Cabal, who make it pleasant to write elaborate object oriented Perl.
Without the use of roles I don't think I would have tried this.

=cut
