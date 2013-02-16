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

		# Element root = parse("");
		# Path<Element> p = new XMLToyForester().path("//a/b[1]");
		# List<Element> bs = p.select(root);
		# assertEquals(2, bs.size());
		# assertEquals("2", bs.get(0).attributes.get("foo"));
		# assertEquals("3", bs.get(1).attributes.get("foo"));
$p        = parse('<root><a><b foo="1"/><b foo="2"/><b foo="3"/></a><a><b foo="2"/><b foo="3"/></a></root>');
@elements = $f->path('//a/b[1]')->select($p);
is( scalar @elements,2, "found the right number of elements with //b[1] on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );
is( $elements[1]->attribute('foo'), '3', 'found expected attribute' );

done_testing();
