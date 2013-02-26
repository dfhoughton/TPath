# what expressions we can make ASTs for

use strict;
use warnings;

use TPath::Grammar qw(parse);
use Test::More;
use Test::Exception;
use List::MoreUtils qw(natatime);

# a bunch of expressions licensed by the spec
my @parsable = make_paths(<<'END');
a[@b(not @c)]
a
~a~
~a~~b~
//foo
id(bar)
/..
/.
/>a
child::a
ancestor-or-self::a
leaf::a
/b/leaf::a
/a/b
/a[@test]
/a[@t-est]
/a[@t:est]
/a[@t3st]
/a[@_test]
/a[@$test]
/a[@test(.)]
/a[@test(1)]
/a[@test("foo")]
/a[@test("fo'o")]
/a[@test("fo\"o")]
/a[@test('foo')]
/a[@test('fo"o')]
/a[@test('fo\'o')]
/a[@test(@foo)]
/a[@test(1,2)]
/a[1 < @test]
/a[1 = @test]
/a[1 == @test]
/a[1 <= @test]
/a[1 >= @test]
/a[1 != @test]
/a[@test > 1]
/a[! a]
/a[(a)]
/a[a^b]
/a[a ^ b]
/a[a&b]
/a[a||b]
/a[0][@test]
/a[b[c]]
/a|//b
//b:b
//b:b[@attr != "1"]
//b:b[@attr(1) != "1"]
//b:b[@attr("fo:o") != "1"]
END

# pairs of expressions that should have the same ASTs
my @equivalent = make_paths(<<'END');
a[b]
a[(b)]

a[b]
a[(((b)))]

a[@b or @c]
a[@b || @c]

a[@b or @c & @d]
a[@b or (@c & @d)]

a[@b or @c or @d or @e]
a[@b or ((@c or @d) or @e)]

a[@b]
a[!!@b]

a[!@b]
a[!!!@b]
END

# some leaf values to test
my @leaves = make_paths(<<'END');
a[@b = 'foo']
v
foo

a[@b]
aname
b

~a~~b~
pattern
a~b

/>a
separator
/>

a[@\'b]
aname
'b

id(\))
id
)

//\3
specific
3

//a[9]
idx
9

//a[-1]
idx
-1

//a[@b = 'fo\'o']
v
fo'o

//a[@b = "fo\"o"]
v
fo"o

//a[@b('c')]
v
c

//a[@b(1)]
v
1
END

plan tests => @parsable + @equivalent / 2 + @leaves / 3;

for my $e (@parsable) {
    lives_ok { parse($e) } "can parse $e";
}

my $i = natatime 2, @equivalent;
while ( my ( $left, $right ) = $i->() ) {
    is_deeply parse($left), parse($right), "$left  ~  $right";
}

$i = natatime 3, @leaves;
while ( my ( $expression, $key, $value ) = $i->() ) {
    is leaf( $expression, $key ), $value,
      "the value of $key in $expression is $value";
}

#done_testing();

sub leaf {
    my ( $expression, $key ) = @_;
    my $ref = parse($expression);
    return find_leaf( $ref, $key );
}

sub find_leaf {
    my ( $ref, $key ) = @_;
    my $type = ref $ref;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            return $v if $k eq $key;
            my $r = find_leaf( $v, $key );
            return $r if defined $r;
        }
        return undef;
    }
    if ( $type eq 'ARRAY' ) {
        for my $v (@$ref) {
            my $r = find_leaf( $v, $key );
            return $r if defined $r;
        }
        return undef;
    }
    return undef;
}

# convert a stringified list of expressions into the expressions to test
sub make_paths {
    my $text = shift;
    grep { $_ !~ /^#/ }
      map { ( my $v = $_ ) =~ s/^\s++|\s++$//g; $v ? $v : () }
      $text =~ /^.*$/gm;
}

