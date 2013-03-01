package TPath;

# ABSTRACT: general purpose path languages for trees

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION



=head1 SYNTAX

=head2 Sub-Paths

A tpath expression has one or more sub-paths.

  B<//a/b>|preceding::d/*
  //a/b|B<preceding::d/*>

=head2 Steps

  B<//a>/b[0]/E<gt>c[@d]
  //aB</b[0]>/E<gt>c[@d]
  //a/b[0]B</E<gt>c[@d]>

=head2 Separators

  a/b/c/E<gt>d
  B</>aB</>b//c/E<gt>d
  B<//>a/bB<//>c/E<gt>d
  B</E<gt>>a/b//cB</E<gt>>d

=head3 null separator

  a/b/c/E<gt>d

=head3 /

  B</>aB</>b//c/E<gt>d

=head3 // select among descendants

  B<//>a/bB<//>c/E<gt>d

=head3 /> select closest

  B</E<gt>>a/b//cB</E<gt>>d

=head2 Selectors

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

=head1 APPLICATION

=head2 Foresters

=head2 Indices

=cut
