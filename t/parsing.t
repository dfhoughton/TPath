# what expressions we can make ASTs for

use strict;
use warnings;

use TPath::Grammar qw(parse);
use Test::More;
use Test::Exception;

my @parsable =
  grep { $_ !~ /^#/ }
  map { ( my $v = $_ ) =~ s/^\s++|\s++$//g; $v ? $v : () } <<'END' =~ /^.*$/gm;
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
#/a[@test('fo\'o')]
/a[@test(@foo)]
/a[@test(1,2)]
/a[1 < @test]
/a[1 = @test]
/a[1 == @test]
/a[1 <= @test]
/a[1 >= @test]
/a[1 != @test]
/a[@test > 1]
/a[0][@test]
/a|//b
END

for my $e (@parsable) {
    lives_ok { parse($e) } "can parse $e";
}

done_testing();

