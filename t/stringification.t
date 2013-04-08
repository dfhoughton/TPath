# makes sure stringification of an expression is semantically identical to the original

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use Test::Exception;
use ToyXMLForester;

my $f = ToyXMLForester->new;

my @paths = grep /^\s*+\S(?<!#)/, <<'EOF' =~ /.*/mg;
a
//a
//*[@attr('b')]
descendant::*
descendant::@attr('b')
^a
/>a
/>@attr('b')
a[@attr('b') or @attr('c')]
a[@attr('b') and @attr('c')]
a[@attr('b') one @attr('c')]
a[!@attr('b') one @attr('c')]
a[@attr('b') or @attr('c') and @attr('d')]
a[(@attr('b') or @attr('c')) and @attr('d')]
/a/b
/a//b
\.a\\
:"a b"
/a/"b c"
/a//"b c"
a[1]
a[b]
a[@attr('b')]
a[@attr('b') = 1]
a[@attr('b') == 1]
a[@attr('b') =~ 'b']
^a
^@attr('b')
~a~
~a~~b~
a?
a+
a*
a{,2}
a{2,}
a{2}
a{2,3}
(a/b){2}
:root/a
:id(foo)/a
.
..
EOF

plan tests => @paths * 3;

for my $path (@paths) {
    my ( $p1, $p2 );
    lives_ok { $p1 = $f->path($path) };
    lives_ok { $p2 = $f->path("$p1") };
    is_deeply $p1, $p2;
}
done_testing();
