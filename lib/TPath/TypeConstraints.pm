package TPath::TypeConstraints;

# ABSTRACT: assorted type constraints

use Moose::Util::TypeConstraints;
use TPath::Grammar qw(%AXES);

class_type $_ for qw(TPath::Attribute TPath::Expression TPath::AttributeTest);

role_type $_ for qw(TPath::Test::Boolean);

union 'ATArg', [qw( Num TPath::Attribute Str )];

union 'CondArg', [qw(TPath::Attribute TPath::Expression TPath::AttributeTest TPath::Test::Boolean)];

enum 'Axis' => values %AXES;
