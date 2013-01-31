package TPath::AttributeTest;

# ABSTRACT : compares an attribute value to another value

use feature qw(switch);
use Moose;
use MooseX::Privacy;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype ATArg =>
  ( as 'Str|Num|TPath::Attribute|TPath::Expression|TPath::AttributeTest' );

has func => ( is => 'rw', isa => 'CodeRef', traits => ['Private'], );

has op => ( is => 'ro', isa => 'Str', required => 1, traits => ['Private'], );

has left =>
  ( is => 'ro', isa => 'ATArg', required => 1, traits => ['Private'] );

has right =>
  ( is => 'ro', isa => 'ATArg', required => 1, traits => ['Private'] );

sub BUILD {
    my $self = shift;
    given ( $self->op ) {
        when ('=') {
            $self->func(
                sub {
                    my ( $l, $r ) = @_;
                    my $type = ref $l;
                    if ($type) {
                        if ( $type eq 'Array' ) {
                            $type = ref $r;
                            return @$l == @$r if $type eq 'Array';
                        }
                        elsif ( $l->can('equals') ) {
                            return $l->equals($r);
                        }
                        else {
                            return "$l" eq "$r";
                        }
                    }
                    "$l" eq "$r";
                }
              )
        }
        when ('==') {
            $self->func(
                sub { my ( $l, $r ) = @_; ref $l && ref $r && $l == $r } )
        }
        when ('<=') {
            $self->func(
                sub { my ( $l, $r ) = @_; ref $l && ref $r && $l == $r } )
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
