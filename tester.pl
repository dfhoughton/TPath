#!/usr/bin/perl 
#
# for examining ASTs

use lib qw(t lib);
use TPath::Grammar qw(parse);
use Data::Dumper;
use Perl::Tidy;

my $parse = parse(q{//a//b|
    //a #comment
    
    //b #comment
});
my $code  = Dumper $parse;
my $ds;
Perl::Tidy::perltidy( argv => ['-l=0'], source => \$code, destination => \$ds );
print $ds;
