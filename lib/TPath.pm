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
  with 'TPath::Attributes::Extended';
  
  # implement required methods
  
  sub children {
      my ( $self, $n ) = @_;
      @{ $n->{children} };
  }
  
  sub has_tag {
      my ( $self, $n, $str ) = @_;
      $str eq $n->{tag};
  }
  
  sub matches_tag {
      my ( $self, $n, $rx ) = @_;
      $n->{tag} =~ $rx;
  }
  
  # implement a useful attribute -- @tag
  
  sub tag : Attr {
      my ( $self, $n, $c, $i ) = @_;
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
  
  # find all nodes with the tag r
  my @nodes = $rhood->path('//r')->select( $root, $index );
  print scalar @nodes, "\n";    # 1
  print $nodes[0], "\n";        # <r><x/><y><z/></y></r>
  
  # find all leaves whose tag alphabetically follows o
  print $_
    for $rhood->path('leaf::*[@tag > "o"]')->select( $root, $index )
    ;                           # <s/><t/><u/><v/><w/><q/><x/><z/>
  print "\n";
  
  # find the nodes dominating a sub-tree of size 3
  print $_->{tag}
    for $rhood->path('//@echo(@tsize = 3)')->select( $root, $index );    # bm
  print "\n";
  
  # find the closest (see below) nodes whose tag matches /[bh-z]/
  @nodes = $rhood->path('/>@s:matches(@tag,"[bh-z]")')->select( $root, $index );
  print $_->{tag} for @nodes;                                            # bhijk
  print "\n";
  
  # we can map nodes back to their parents even though the nodes themselves
  # do not retain this information
  
  # find the nodes whose parent's tag is a, d, or r
  @nodes = $rhood->path('//*[parent::*[@s:matches(@tag, "[adr]")]]')
    ->select( $root, $index );
  print $_->{tag} for @nodes;    # bcijxykd
  print "\n";

=head1 DESCRIPTION

TPath provides an XPath-like language for arbitrary trees. You implement a minimum of three
methods -- C<children>, C<has_tag>, and C<matches_tag> -- and you can explore your trees via
concise, declarative paths.

In TPath, "attributes" are node attributes of any sort and are implemented as methods that 
return these attributes, or C<undef> if the attribute is undefined for the node.

The object in which the three required methods are implemented is a "forester" (L<TPath::Forester>),
something that understands your trees.

Forester objects make use of an index (L<TPath::Index>), which caches information not present in, or
not cheaply from, the nodes themselves. If no index is explicitly provided it is created, but one
can gain some efficiency by reusing an index when select paths from a tree.

The paths themselves are compiled into reusable objects that can be applied to multiple trees.

=head1 ALGORITHM

TPath works by representing an expression as a pipeline of selectors and filters. Each pair of a
selector and some set of filters is called a "step". At each step one has a set of context nodes.
One applies the selectors to each context node, returning a candidate node set, and then one passes
these candidates through the filtering predicates. The remainder becomes the context node set
for the next step.

=head1 SYNTAX

=head2 Sub-Paths

A tpath expression has one or more sub-paths.

  B<//a/b>|preceding::d/*
  //a/b|B<preceding::d/*>

The nodes selected by a path is the union of the nodes selected by each sub-path in the order of
their discovery. The search is left-to-right and depth first. If a node and its descendants are both selected, the
descendants will be listed first.

=head2 Steps

  B<//a>/b[0]/E<gt>c[@d]
  //aB</b[0]>/E<gt>c[@d]
  //a/b[0]B</E<gt>c[@d]>

Each step consists of a separator (optional on the first step), a tag selector, and optionally some
number of predicates.

=head2 Separators

  a/b/c/E<gt>d
  B</>aB</>b//c/E<gt>d
  B<//>a/bB<//>c/E<gt>d
  B</E<gt>>a/b//cB</E<gt>>d

=head3 null separator

  a/b/c/E<gt>d
  
The null separator is simply the absence of a separator. It means "relative to the
context node". Thus is it essentially the same as the file path formalism, where C</a> means
the file C<a> in the root directory and C<a> means the file C<a> in the current directory.

=head3 /

  B</>aB</>b//c/E<gt>d

The single slash separator means "search among the context node's children", or if it precedes
the first step it means that the context node is the root node.

=head3 // select among descendants

  B<//>a/bB<//>c/E<gt>d
  
The double slash separator means "search among the descendants of the context node" or, if the
context node is the root, "search among the root node and its descendants".

=head3 /> select closest

  B</E<gt>>a/b//cB</E<gt>>d

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
lefmost leaf C<b>, which is screened from the root by its grandparent C<b> node. That is, going down
any path from the context node C</E<gt>b> will match the first node it finds matching the selector --
the matching node closest to the context node.

=head2 Selectors

Selectors select a candidate set for later filtering by predicates.

=head3 literal

  B<a>

A literal selector selects the nodes whose tag matches, in a tree-appropriate sense of "match",
a literal expression.

Any string may be used to represent a literal selector, but certain characters may have to be
escaped with a backslash. The expectation is that the literal with begin with a word character, _,
or C<$> and any subsequent character is either one of these characters, a number character or 
a hyphen or colon followed by one of these or number character. The escape character, as usual, is a
backslash. Any unexpected character must be escaped. So

   a\\b

represents the literal C<a\b>.

=head3 ~a~ regex

  ~a~

A regex selector selects the nodes whose tag matches a regular expression delimited by tildes. Within
the regular expression a tilde must be escaped, of course. A tilde within a regular expression is
represented as a pair of tildes. The backslash, on the other hand, behaves as it normally does within
a regular expression.

=head3 @a attribute

Any attribute may be used as a selector so long as it is preceded by some separator other than
the null separator. This is because attributes may take arguments and among other things these
arguments can be both expressions and other attributes. If C<@foo> were a legitimate path
expression it would be ambiguous how to compile C<@bar(@foo)>. Is the argument an attribute or
a path with an attribute selector. You can produce the effect of an attribute selector with the
null separator, however, by using the child axis (see below). If you want the argument to be
a path, you write

  child::@bar(child::@foo)

If you want it to be an ordinary attribute, you write

  child::@bar(@foo)
  
If the first instance the C<@bar> attribute receives a list of nodes as its arguments. In the second,
it receives whatever C<@foo> evaluates to at the candidate node in question.

=head3 * wildcard

=head2 Axes

=head2 Predicates

  //a/bB<[0]>/E<gt>c[@d][@e < 'string']
  //a/b[0]/E<gt>B<c[@d]>[@e < 'string']
  //a/b[0]/E<gt>c[@d]B<[@e < 'string']>

=head2 Index Predicates

=head2 Attributes

=head2 Attribute Tests

=head2 Special Selectors

There are three special selectors B<that cannot occur with predicates>.

=head3 . : Select Self

This is an abbreviation for C<self::*>.

=head3 .. : Select Parent

This is an abbreviation for C<parent::*>.

=head3 id(foo) : Select By Index

This selector selects the node, if any, with the given id. This same node can also be selected
by C<//*[@id = 'foo']> but this is much less efficient.

=head1 HISTORY

I wrote TPath initially in Java because I wanted a more convenient way to select nodes from
parse trees. I've re-written it in Perl because I figured it might be handy and why not?

=cut
