package TPath::TypeConstraints;

# ABSTRACT : assorted type constraints

use Moose::Util::TypeConstraints;

class_type $_ for qw(TPath::Attribute TPath::Expression TPath::AttributeTest);

union 'ATArg',
  [qw( Num TPath::Attribute TPath::Expression TPath::AttributeTest Str )];
