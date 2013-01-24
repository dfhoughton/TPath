# what expressions we can make ASTs for

use strict;
use warnings;

use TPath::Grammar;
use Test::More;
use Test::Exception;

my @parsable =
  map { ( my $v = $_ ) =~ s/^\s++|\s++$//g; $v ? $v : () } <<'END' =~ /^.*$/gm;
//foo
id(bar)
/..
/.
/>a
/a[@test(.)]
END

for my $e (@parsable) {
    lives_ok { parse($e) } "can parse $e";
}

done_testing();

