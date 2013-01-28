# what expressions we can make ASTs for

use strict;
use warnings;

use TPath::Grammar qw(parse);
use Test::More;
use Test::Exception;
use List::MoreUtils qw(natatime);

# convert a stringified list of expressions into the expressions to test
sub make_paths {
    my $text = shift;
    grep { $_ !~ /^#/ }
      map { ( my $v = $_ ) =~ s/^\s++|\s++$//g; $v ? $v : () }
      $text =~ /^.*$/gm;
}

# a bunch of expressions licensed by the spec
my @parsable = make_paths(<<'END');
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

plan tests => @parsable + @equivalent / 2;

for my $e (@parsable) {
    lives_ok { parse($e) } "can parse $e";
}

my $i = natatime 2, @equivalent;
while ( my ( $left, $right ) = $i->() ) {
    is_deeply parse($left), parse($right), "$left  ~  $right";
}

#done_testing();

