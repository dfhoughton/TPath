# tests logical precedence

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More; # tests => 55;
use ToyXMLForester;
use ToyXML qw(parse);

my $p = parse(q{<a><b c="1"/><b d="1"/><b c="1" d="1"/><b/><b c="1" d="1" e="1"/><b c="1" e="1"/></a>});
my $f = ToyXMLForester->new;
my $i = $f->index($p);
my ($path, @elements);

$path = '//*[@attr("c") & @attr("d")]';
@elements = $f->path($path)->select($p, $i);
is @elements, 2, "correct number of elements with $path";

done_testing();
