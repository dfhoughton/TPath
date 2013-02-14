package TPath::TypeConstraints;

# ABSTRACT: assorted type constraints

use Moose::Util::TypeConstraints;
use TPath::Grammar qw(%AXES);

class_type $_ for qw(TPath::Attribute TPath::Expression TPath::AttributeTest);

union 'ATArg',
  [qw( Num TPath::Attribute TPath::Expression TPath::AttributeTest Str )];
  
enum 'Axis' => values %AXES;
