package TPath::Attributes::Extended;

# ABSTRACT : a collection of attributes beyond the standard set

=head1 SYNOPSIS

  # mix in the extended attribute set

  {
    package BetterForester;
    use Moose;
    extends 'MyForester';
    with 'TPath::Attributes::Extended';
  }

  my $f        = BetterForester->new;
  my $path     = $f->path('//*[@s:concat("", children::*) = "blarmy"]'); # new attribute!
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

sub mabs : Attr(m%3Aabs) {
    abs $_[4];
}

=method C<@m:ceil(1.5)>

Returns smallest whole number greater than or equal to the numeric argument.

=cut

sub mceil : Attr(m%3Aceil) {
    require POSIX;
    POSIX::ceil( $_[4] );
}

=method C<@m:floor(1.5)>

Returns largest whole number less than or equal to the numeric argument.

=cut

sub mfloor : Attr(m%3Afloor) {
    require POSIX;
    POSIX::floor( $_[4] );
}

=method C<@m:int(1.5)>

Returns integer portion of the numeric argument.

=cut

sub mint : Attr(m%3Aint) {
    int $_[4];
}

=method C<@m:round(1.5)>

Rounds numeric argument to the nearest whole number relying on C<sprintf '%.0f'>
for the rounding.

=cut

sub round : Attr(m%3Around) {
    sprintf '%.0f', $_[4];
}

=method C<@m:max(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the maximum, treating them as numbers.

=cut

sub mmax : Attr(m%3Amax) {
    max @_[ 4 .. $#_ ];
}

=method C<@m:min(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the minimum, treating them as numbers.

=cut

sub mmin : Attr(m%3Amin) {
    min @_[ 4 .. $#_ ];
}

=method C<@m:sum(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the sum, treating them as numbers.

=cut

sub msum : Attr(m%3Asum) {
    sum @_[ 4 .. $#_ ];
}

=method C<@m:prod(1,2,3,4,5)>

Takes an arbitrary number of arguments and returns the product, treating them as numbers.
An empty list returns 0.

=cut

sub prod : Attr(m%3Aprod) {
    0 + reduce { $a * $b } @_[ 4 .. $#_ ];
}

=method C<@s:matches('str','re')>

Returns whether the given string matches the given regex. That is,
if the regex is C<$re>, the regex tested against is C<^$re$>.

=cut

sub matches : Attr(s%3Amatches) {
    my ( $str, $re ) = @_[ 4, 5 ];
    $str =~ /^$re$/;
}

=method C<@s:looking-at('str','re')>

Returns whether a prefix of the given string matches the given regex.
That is, if the regex given is C<$re>, the regex tested against is
C<^$re>.

=cut

sub looking_at : Attr(s%3Alooking-at) {
    my ( $str, $re ) = @_[ 4, 5 ];
    $str =~ /^$re/;
}

=method C<@s:find('str','re')>

Returns whether a prefix of the given string matches the given regex anywhere.

=cut

sub find : Attr(s%3Alfind) {
    my ( $str, $re ) = @_[ 4, 5 ];
    $str =~ /$re/;
}

=method C<@s:starts-with('str','prefix')>

Whether the string has the given prefix.

=cut

sub starts_with : Attr(s%3Astarts-with) {
    my ( $str, $prefix ) = @_[ 4, 5 ];
    0 == index $str, $prefix;
}

=method C<@s:ends-with('str','suffix')>

Whether the string has the given suffix.

=cut

sub ends_with : Attr(s%3Aends-with) {
    my ( $str, $suffix ) = @_[ 4, 5 ];
    -1 < index $str, $suffix, length($str) - length($suffix);
}

=method C<@s:contains('str','infix')>

Whether the string contains the given substring.

=cut

sub contains : Attr(s%3Acontains) {
    my ( $str, $infix ) = @_[ 4, 5 ];
    -1 < index $str, $infix;
}

=method C<@s:index('str','substr')>

The index of the substring within the string.

=cut

sub sindex : Attr(s%3Aindex) {
    my ( $str, $infix ) = @_[ 4, 5 ];
    index $str, $infix;
}

=method C<@s:concat('foo','bar','baz','quux','plugh')>

Takes an arbitrary number of arguments and returns their concatenation as a string.

=cut

sub concat : Attr(s%3Aconcat) {
    join '', @_[ 4 .. $#_ ];
}

=method C<@s:replace-first('str','rx','rep')>

Takes a string, a pattern, and a replacement and returns the string, replacing
the first pattern match with the replacement.

=cut

sub replace_first : Attr(s%3Areplace-first) {
    my ( $str, $rx, $rep ) = @_[ 4 .. 6 ];
    $str =~ s/$rx/$rep/;
    $str;
}

=method C<@s:replace-all('str','rx','rep')>

Takes a string, a pattern, and a replacement and returns the string, replacing
every pattern match with the replacement.

=cut

sub replace_all : Attr(s%3Areplace-all) {
    my ( $str, $rx, $rep ) = @_[ 4 .. 6 ];
    $str =~ s/$rx/$rep/g;
    $str;
}

=method C<@s:replace('str','substr','rep')>

Takes a string, a substring, and a replacement and returns the string, replacing
every literal occurrence of the substring with the replacement string.

=cut

sub replace : Attr(s%3Areplace) {
    my ( $str, $ss, $rep ) = @_[ 4 .. 6 ];
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

sub compare : Attr(s%3Acmp) {
    my ( $s1, $s2 ) = @_[ 4, 5 ];
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

sub ssubstr : Attr(s%3Asubstr) {
    my ( $s, $i1, $i2 ) = @_[ 4 .. 6 ];
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

sub len : Attr(s%3Alen) {
    length $_[4];
}

=method C<@s:uc('str')>

The string parameter in uppercase.

=cut

sub suc : Attr(s%3Auc) {
    uc $_[4];
}

=method C<@s:lc('str')>

The string parameter in lowercase.

=cut

sub slc : Attr(s%3Alc) {
    lc $_[4];
}

=method C<@s:ucfirst('str')>

The function C<ucfirst> applied to the string parameter.

=cut

sub uc_first {
    ucfirst $_[4];
}

=method C<@s:trim('str')>

Removes marginal whitespace from string parameter.

=cut

sub trim : Attr(s%3Atrim) {
    ( my $s = $_[4] ) =~ s/^\s++|\s++$//g;
    $s;
}

=method C<@s:nspace('str')>

Normalizes all whitespace in string parameter, stripping off marginal
space and converting all interior space sequences into single whitespaces.

=cut

sub nspace : Attr(s%3Anspace) {
    my $s = trim(@_);
    $s =~ s/\s++/ /g;
    $s;
}

=method C<@s:join('sep',s1','s2','s3')>

Joins together a list of arguments with the given separator. The arguments and separator
will all be stringified. If the separator is undefined, its stringification will be
C<null> to keep it semantically equivalent to the Java version of C<@s:join>.

=cut

sub sjoin : Attr(s%3Ajoin) {
    my ( $sep, @strings ) = @_[ 4 .. $#_ ];
    $sep //= 'null';
    join "$sep", @strings;
}

=method C<@u:millis>

The system time in milliseconds. 

=cut

sub millis : Attr(u%3Amillis) {
    require Time::HiRes;
    my ( $s, $m ) = Time::HiRes::gettimeofday();
    $m = int( $m / 1000 );
    $s * 1000 + $m;
}

=method C<@u:def(@arg)>

Whether the argument is defined.

=cut

sub udef : Attr(u%3Adef) {
    defined $_[4];
}

1;
