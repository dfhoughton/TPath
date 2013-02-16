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
is( 4, scalar @elements, "found the right number of elements with //b on $p" );
is( '<b/>', $_, 'correct element' ) for @elements;

$p = parse('<a><b><b/></b><b/></a>');
my @elements = $f->path('//b//b')->select($p);
is(
    1,
    scalar @elements,
    "found the correct number of elements with //b//b on $p"
);
is( '<b/>', $_, 'correct element' ) for @elements;

$p = parse('<a><a/></a>');
my @elements = $f->path('//a')->select($p);
is( 2, scalar @elements, "found the right number of elements with //a on $p" );

$p = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
my @elements = $f->path('/b')->select($p);
is( 0, scalar @elements, "found the right number of elements with /b on $p" );

done_testing();
