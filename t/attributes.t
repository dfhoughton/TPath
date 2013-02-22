# checks whether attributes are working as expected

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;# tests => 55;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;
my ($p, $path, @c);

$p = parse(q{<a><b/><b foo="bar"/></a>});
$path = q{//b[@attr('foo')]};
@c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p = parse(q{<a><b><c/></b><b/></a>});
$path = q{//b[c]};
@c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p = parse(q{<a><b><c/><c/></b><b><c/></b><b/></a>});
$path = q{//b[c]};
@c = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

done_testing();