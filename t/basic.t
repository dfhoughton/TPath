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

$p    = parse('<a><b/><c/></a>');
$path = '/a/*';
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

for my $line ( <<END =~ /^.*$/mg ) {
<root><a><b/><c><a/></c></a><b><b><a><c/></a></b></b></root>
//root 1
//a 3
//b 3
//c 2
<root><c><b><a/></b></c></root>
//root 1
//a 1
//b 1
//c 1
END
    if ( $line !~ / / ) {
        $p = parse($line);
        next;
    }
    my ( $l, $r ) = split / /, $line;
    $path = $l;
    my $expectation = $r;
    @elements = $f->path($path)->select($p);
    is scalar @elements, $expectation,
      "got expected number of elements for $path on $p";
}

$p = parse(
'<a><b id="foo"><c/><c/><c/></b><b id="bar"><c/></b><b id="(foo)"><c/><c/></b></a>'
);
for my $line ( <<'END' =~ /^.*$/mg ) {
id(foo)/* 3
id(bar)/* 1
id(\(foo\))/* 2
END
    my ( $l, $r ) = split / /, $line;
    $path = $l;
    my $expectation = $r;
    @elements = $f->path($path)->select($p);
    is scalar @elements, $expectation,
      "got expected number of elements for $path on $p";
}

$f->add_attribute(
    'foobar',
    sub {
        my ( $self, $n, $c, $i ) = @_;
        return defined $n->attribute('foo') && defined $n->attribute('bar');
    }
);
$p        = parse(q{<a><b foo="bar" bar="foo"/><b foo="foo"/></a>});
$path     = '//*[@foobar]';
@elements = $f->path($path)->select($p);
is scalar @elements, 1, "got element from $p using new attribute \@foobar";

$p        = parse(q{<a><b foo="bar" bar="foo"/><b foo="foo"/></a>});
$path     = '//*[@attr("foo")]';
@elements = $f->path($path)->select($p);
is scalar @elements, 2, "correct number of elements in $p with $path";
my $v = $f->attribute( $elements[0], 'attr', undef, undef, 'foo' );
is $v, 'bar', "correct value of attribute";

$p        = parse(q{<a><b><c/></b><foo><d/><e><foo/></e></foo></a>});
$path     = '/>foo/preceding::*';
@elements = $f->path($path)->select($p);
is scalar @elements, 2, "correct number of elements selected from $p by $path";
my %set = map { $_ => 1 } @elements;
ok $set{'<c/>'},        "found <c/>";
ok $set{'<b><c/></b>'}, "found <b><c/></b>";

$p        = parse(q{<a><b><c/></b><foo><d/><e><foo/></e></foo></a>});
$path     = '/leaf::*';
@elements = $f->path($path)->select($p);
is scalar @elements, 3, "correct number of elements selected from $p by $path";
my %set = map { $_ => 1 } @elements;
ok $set{'<c/>'},   "found <c/>";
ok $set{'<d/>'},   "found <d/>";
ok $set{'<foo/>'}, "found <foo/>";

done_testing();
