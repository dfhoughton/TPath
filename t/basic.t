# runs through some basic expressions

use strict;
use warnings;

use Test::More;
use ToyXMLForester;
use ToyXML qw(parse);

# Element root = parse("<a><b/><c><b/><d><b/><b/></d></c></a>");
# Path<Element> p = new XMLToyForester().path("//b");
# Collection<Element> bs = p.select(root);
# assertEquals(4, bs.size());
# my $f = ToyXMLForester->new;
# lives_ok { ToyXMLForester->new } "can construct a ToyXMLForester";
my $p = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
print $p, "\n";
my $f = ToyXMLForester->new;
print $_, "\n" for $f->path('//b')->select($p);