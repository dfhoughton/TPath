# makes sure matching is working in attribute tests

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
	push @INC, dirname($0);
}

use Test::More;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my $p        = parse('<aa><ba><a/></ba><b/></aa>');
my $path     = q{//*[@tag =~ '(?<!b)a']};
my @elements = $f->path($path)->select($p);
is( scalar @elements, 2,
	"found the right number of elements with $path on $p" );
is $elements[0]->tag, 'a',  'correct first element';
is $elements[1]->tag, 'aa', 'correct second element';

$path     = q{//*[@tag !~ 'b']};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
	"found the right number of elements with $path on $p" );
is $elements[0]->tag, 'a',  'correct first element';
is $elements[1]->tag, 'aa', 'correct second element';

$path     = q{//*[@tag =~ @tag]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 4,
	"found the right number of elements with $path on $p" );

$path     = q{//*[@tag !~ @tag]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 0,
	"found the right number of elements with $path on $p" );

done_testing();
