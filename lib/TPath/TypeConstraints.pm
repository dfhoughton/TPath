package TPath::TypeConstraints;

# ABSTRACT: assorted type constraints

use Moose::Util::TypeConstraints;
use TPath::Grammar qw(%AXES);

class_type $_
  for
  qw(TPath::Attribute TPath::Expression TPath::AttributeTest TPath::Math TPath::Function);

role_type $_
  for
  qw(TPath::Test::Boolean TPath::Selector TPath::Forester TPath::Predicate TPath::Numifiable);

union 'ATArg', [qw( Num TPath::Numifiable Str )];

union 'CondArg',
  [
    qw(TPath::Attribute TPath::Expression TPath::AttributeTest TPath::Test::Boolean)
  ];

union 'MathArg', [qw(TPath::Numifiable Num)];

enum 'Quantifier' => qw( * + ? e );

enum 'Axis' => keys %AXES;
