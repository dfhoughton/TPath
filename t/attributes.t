# checks whether attributes are working as expected

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;    # tests => 55;
use Test::Trap;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;
my ( $p, $path, @c );

$p    = parse(q{<a><b/><b foo="bar"/></a>});
$path = q{//b[@attr('foo')]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b><c/></b><b/></a>});
$path = q{//b[c]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b><c/><c/></b><b><c/></b><b/></a>});
$path = q{//b[c]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b foo="1"/><b foo="2"/><b foo="3"/></a>});
$path = q{//b[@log(@attr('foo'))]};
trap { @c = $f->path($path)->select($p) };
is @c, 3, "received expected from $p with $path";
is $trap->stderr, "1\n2\n3\n", 'received correct log messages';
my $message_log = '';
{

    package MyLog;
    use Moose;
    with 'TPath::LogStream';

    sub put {
        my ( $self, $msg ) = @_;
        $message_log .= "$msg\n";
    }
}
$f->log_stream( MyLog->new );
$f->path($path)->select($p);
is $message_log, "1\n2\n3\n", 'able to replace message log';
$f->log_stream( TPath::StderrLog->new );

$p    = parse(q{<a><b id="foo"><c/><c/><c/></b><b id="bar"><c/></b></a>});
$path = q{//b[@id = 'foo']/*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";
$path = q{//b[@id = 'bar']/*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b id='foo'/></a>});
$path = q{//b[@log(@id = 'foo')]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "1\n",
  "attribute test evaluated as expected in $p with $path";

$p    = parse q{<a><b/><b foo='bar' /></a>};
$path = q{//b[@false]};
@c    = $f->path($path)->select($p);
is @c, 0, '@false attribute works';

$p    = parse q{<a><b/><b id='bar' /></a>};
$path = q{//b[@id = 'bar' and @index = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b id='bar' /><a/></a>};
$path = q{//a[@root]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@size(*) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@pick(*, 1) = '<c/>']};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b></b></a>};
$path = q{//b[@leaf]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@pick(*, 1) == @null]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

done_testing();
