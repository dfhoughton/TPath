# runs through some basic expressions

use strict;
use warnings;

use Test::More;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);

my $f;
lives_ok { $f = ToyXMLForester->new } "can construct a ToyXMLForester";

my $p        = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
my @elements = $f->path('//b')->select($p);
is( scalar @elements, 4, "found the right number of elements with //b on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$p        = parse('<a><b><b/></b><b/></a>');
@elements = $f->path('//b//b')->select($p);
is( scalar @elements,
    1, "found the correct number of elements with //b//b on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$p        = parse('<a><a/></a>');
@elements = $f->path('//a')->select($p);
is( scalar @elements, 2, "found the right number of elements with //a on $p" );

$p        = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
@elements = $f->path('/b')->select($p);
is( scalar @elements, 0, "found the right number of elements with /b on $p" );

$p        = parse('<a><b/></a>');
@elements = $f->path('/.')->select($p);
is( scalar @elements, 1, "found the right number of elements with /. on $p" );
is( $elements[0]->tag, 'a', 'correct tag on element selected' );

$p        = parse('<a><b/><c><b><d><b/></d></b></c></a>');
@elements = $f->path('/>b')->select($p);
is( scalar @elements, 2, "found the right number of elements with />b on $p" );

$p        = parse('<a><c><d><b/></d></c><b/></a>');
@elements = $f->path('//c//b')->select($p);
is( scalar @elements,
    1, "found the right number of elements with //c//b on $p" );

$p        = parse(q{<a><b foo="1"/><b foo="2"/><b foo="3"/></a>});
@elements = $f->path('//b[1]')->select($p);
is( scalar @elements,
    1, "found the right number of elements with //b[1] on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );

$p = parse(
'<root><a><b foo="1"/><b foo="2"/><b foo="3"/></a><a><b foo="2"/><b foo="3"/></a></root>'
);
@elements = $f->path('//a/b[1]')->select($p);
is( scalar @elements,
    2, "found the right number of elements with //b[1] on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );
is( $elements[1]->attribute('foo'), '3', 'found expected attribute' );

$p = parse('<a:b><b:b/><b:b fo:o="1"/><b:b fo:o="2"/></a:b>');
my $path = '//b:b[@attr("fo:o") != "1"]';
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );

$p = parse('<a><b/><c/></a>');
my $path = '/a/*';
$f->add_test(
    sub {
        my ( $f, $n, $i ) = @_;
        $f->has_tag( $n, 'c' );
    }
);
@elements = $f->path($path)->select($p);
is(
    scalar @elements,
    1,
    "found the right number of elements with $path on $p when ignoring c nodes"
);
$f->clear_tests;
@elements = $f->path($path)->select($p);
is(
    scalar @elements,
    2,
    "found the right number of elements with $path on $p when not ignoring c nodes"
);

done_testing();
