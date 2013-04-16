package TPath::Attributes::Extended;

# ABSTRACT: a collection of attributes beyond the standard set

=head1 SYNOPSIS

  # mix in the extended attribute set

  {
    package BetterForester;
    use Moose;
    extends 'MyForester';
    with 'TPath::Attributes::Extended';
  }

  my $f        = BetterForester->new;
  my $path     = $f->path('//*[@s:concat("", *) = "blarmy"]'); # new attribute!
  my $tree     = next_tree();
  my @blarmies = $path->select($tree);

=head1 DESCRIPTION

C<TPath::Attributes::Extended> provides a collection of useful functions
generally corresponding to functions available in XPath. The attribute
names of these functions are preceded with a prefix indicating their
domain of application.

=over 8

=item m:

Mathematical functions.

=item s:

String functions.

=item u:

Utility functions.

=back

=cut

use Moose::Role;
use MooseX::MethodAttributes::Role;
use List::Util qw(max min sum reduce);

=method C<@m:abs(-1)>

Absolute value of numeric argument.

=cut

sub extended_abs : Attr(m:abs) {
    abs $_[2];
}

=method C<@m:ceil(1.5)>

Returns smallest whole number greater than or equal to the numeric argument.

=cut

sub extended_ceil : Attr(m:ceil) {
    require POSIX;
    POSIX::ceil( $_[2] );
}

=method C<@m:floor(1.5)>

Returns largest whole number less than or equal to the numeric argument.

=cut

sub extended_floor : Attr(m:floor) {
    require POSIX;
    POSIX::floor( $_[2] );
}

=method C<@m:int(1.5)>

Returns integer portion of the numeric argument.

=cut

sub extended_int : Attr(m:int) {
    int $_[2];
}

=method C<@m:round(1.5)>

Rounds numeric argument to the nearest whole number relying on C<sprintf '%.0f'>
for the rounding.

=cut

sub extended_round : Attr(m:round) {
    sprintf '%.0f', $_[2];
}

=method C<@m:max(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the maximum, treating them as numbers.

=cut

sub extended_max : Attr(m:max) {
    max @_[ 2 .. $#_ ];
}

=method C<@m:min(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the minimum, treating them as numbers.

=cut

sub extended_min : Attr(m:min) {
    min @_[ 2 .. $#_ ];
}

=method C<@m:sum(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the sum, treating them as numbers.

=cut

sub extended_sum : Attr(m:sum) {
    sum @_[ 2 .. $#_ ];
}

=method C<@m:prod(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the product, treating them as numbers.
An empty list returns 0.

=cut

sub extended_prod : Attr(m:prod) {
    0 + reduce { $a * $b } @_[ 2 .. $#_ ];
}

=method C<@s:matches('str','re')>

Returns whether the given string matches the given regex. That is,
if the regex is C<$re>, the regex tested against is C<^$re$>.

=cut

sub extended_matches : Attr(s:matches) {
    my ( $str, $re ) = @_[ 2, 3 ];
    ( $str // '' ) =~ /^$re$/ ? 1 : undef;
}

=method C<@s:looking-at('str','re')>

Returns whether a prefix of the given string matches the given regex.
That is, if the regex given is C<$re>, the regex tested against is
C<^$re>.

=cut

sub extended_looking_at : Attr(s:looking-at) {
    my ( $str, $re ) = @_[ 2, 3 ];
    $str =~ /^$re/ ? 1 : undef;
}

=method C<@s:find('str','re')>

Returns whether a prefix of the given string matches the given regex anywhere.

=cut

sub extended_find : Attr(s:find) {
    my ( $str, $re ) = @_[ 2, 3 ];
    $str =~ /$re/ ? 1 : undef;
}

=method C<@s:starts-with('str','prefix')>

Whether the string has the given prefix.

=cut

sub extended_starts_with : Attr(s:starts-with) {
    my ( $str, $prefix ) = @_[ 2, 3 ];
    0 == index $str, $prefix ? 1 : undef;
}

=method C<@s:ends-with('str','suffix')>

Whether the string has the given suffix.

=cut

sub extended_ends_with : Attr(s:ends-with) {
    my ( $str, $suffix ) = @_[ 2, 3 ];
    -1 < index( $str, $suffix, length($str) - length($suffix) ) ? 1 : undef;
}

=method C<@s:contains('str','infix')>

Whether the string contains the given substring.

=cut

sub extended_contains : Attr(s:contains) {
    my ( $str, $infix ) = @_[ 2, 3 ];
    -1 < index( $str, $infix ) ? 1 : undef;
}

=method C<@s:index('str','substr')>

The index of the substring within the string.

=cut

sub extended_index : Attr(s:index) {
    my ( $str, $infix ) = @_[ 2, 3 ];
    index $str, $infix;
}

=method C<@s:concat('foo','bar','baz','quux','plugh')>

Takes an arbitrary number of arguments and returns their concatenation as a string.

=cut

sub extended_concat : Attr(s:concat) {
    join '', @_[ 2 .. $#_ ];
}

=method C<@s:replace-first('str','rx','rep')>

Takes a string, a pattern, and a replacement and returns the string, replacing
the first pattern match with the replacement.

=cut

sub extended_replace_first : Attr(s:replace-first) {
    my ( $str, $rx, $rep ) = @_[ 2 .. 4 ];
    $str =~ s/$rx/$rep/;
    $str;
}

=method C<@s:replace-all('str','rx','rep')>

Takes a string, a pattern, and a replacement and returns the string, replacing
every pattern match with the replacement.

=cut

sub extended_replace_all : Attr(s:replace-all) {
    my ( $str, $rx, $rep ) = @_[ 2 .. 4 ];
    $str =~ s/$rx/$rep/g;
    $str;
}

=method C<@s:replace('str','substr','rep')>

Takes a string, a substring, and a replacement and returns the string, replacing
every literal occurrence of the substring with the replacement string.

=cut

sub extended_replace : Attr(s:replace) {
    my ( $str, $ss, $rep ) = @_[ 2 .. 4 ];
    my $l     = length $ss;
    my $start = 0;
    my $ns    = '';
    while ( ( my $i = index $str, $ss, $start ) > -1 ) {
        $ns .= substr $str, $start, $i - $start;
        $ns .= $rep;
        $start = $i + $l;
    }
    $l = length $str;
    $ns .= substr $str, $start, $l - $start if $start < $l;
    $ns;
}

=method C<@s:cmp('s1','s2')>

Takes two strings and returns the comparison of the two using C<cmp>.

=cut

sub extended_compare : Attr(s:cmp) {
    my ( $s1, $s2 ) = @_[ 2, 3 ];
    $s1 cmp $s2;
}

=method C<@s:substr('s',1,2)>

Expects a string and one or two indices. If one index is received, returns

  substr $s, $i1

otherwise, returns

  substr $s, $i1, $i2 - $i1

That is, the second index is understood to be an end index rather than the length
of the substring. This is done to make the Perl version of C<@s:substr> semantically
identical to the Java version.

=cut

sub extended_substr : Attr(s:substr) {
    my ( $s, $i1, $i2 ) = @_[ 2 .. 4 ];
    if ( defined $i2 ) {
        substr $s, $i1, $i2 - $i1;
    }
    else {
        substr $s, $i1;
    }
}

=method C<@s:len('str')>

The length of the string parameter.

=cut

sub extended_len : Attr(s:len) {
    length $_[2];
}

=method C<@s:uc('str')>

The string parameter in uppercase.

=cut

sub extended_uc : Attr(s:uc) {
    uc $_[2];
}

=method C<@s:lc('str')>

The string parameter in lowercase.

=cut

sub extended_lc : Attr(s:lc) {
    lc $_[2];
}

=method C<@s:ucfirst('str')>

The function C<ucfirst> applied to the string parameter.

=cut

sub extended_uc_first : Attr(s:ucfirst) {
    ucfirst $_[2];
}

=method C<@s:trim('str')>

Removes marginal whitespace from string parameter.

=cut

sub extended_trim : Attr(s:trim) {
    ( my $s = $_[2] ) =~ s/^\s++|\s++$//g;
    $s;
}

=method C<@s:nspace('str')>

Normalizes all whitespace in string parameter, stripping off marginal
space and converting all interior space sequences into single whitespaces.

=cut

sub extended_nspace : Attr(s:nspace) {
    my $s = extended_trim(@_);
    $s =~ s/\s++/ /g;
    $s;
}

=method C<@s:join('sep',s1','s2','s3')>

Joins together a list of arguments with the given separator. The arguments and separator
will all be stringified. If the separator is undefined, its stringification will be
C<null> to keep it semantically equivalent to the Java version of C<@s:join>.

=cut

sub extended_join : Attr(s:join) {
    my ( $sep, @strings ) = @_[ 2 .. $#_ ];
    $sep //= 'null';
    join "$sep", @strings;
}

=method C<@u:millis>

The system time in milliseconds. 

=cut

sub extended_millis : Attr(u:millis) {
    require Time::HiRes;
    my ( $s, $m ) = Time::HiRes::gettimeofday();
    $m = int( $m / 1000 );
    $s * 1000 + $m;
}

=method C<@u:def(@arg)>

Whether the argument is defined.

=cut

sub extended_udef : Attr(u:def) {
    defined $_[2] ? 1 : undef;
}

1;
