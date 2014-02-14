package TPath::TypeConstraints;

# ABSTRACT: assorted type constraints

use Moose::Util::TypeConstraints;
use TPath::Grammar qw(%AXES);

sub prefix(@);

class_type $_
  for prefix qw(Attribute Expression AttributeTest Math Function Concatenation);

role_type $_
  for prefix qw(Test::Boolean Selector Forester Predicate Numifiable);

union ATArg => [qw( Num TPath::Numifiable Str TPath::Concatenation )];

union CondArg =>
  [ prefix qw(Attribute Expression AttributeTest Test::Boolean) ];

union ConcatArg =>
  [ qw( Num Str ), prefix qw( Attribute Expression Math ) ];

union MathArg => [qw(TPath::Numifiable Num)];

enum Quantifier => [qw( * + ? e )];

enum Axis => [ keys %AXES ];

sub prefix(@) {
    map { "TPath::$_" } @_;
}
