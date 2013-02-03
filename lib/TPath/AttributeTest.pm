package TPath::AttributeTest;

# ABSTRACT : compares an attribute value to another value

use feature qw(switch);
use Scalar::Util qw(looks_like_number);
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
                            return @$l == $r;
                        }
                        elsif ( $l->can('equals') ) {
                            return $l->equals($r);
                        }
                    }
                    else {
                        $type = ref $r;
                        if ($type) {
                            return @$r == $l if $type eq 'ARRAY';
                            return $r->equals($l) if $r->can('equals');
                        }
                    }
                    "$l" eq "$r";
                }
              )
        }
        when ('==') {
            $self->func(
                sub {
                    my ( $l, $r ) = @_;
                    my $type = ref $l;
                    if ($type) {
                        if ( $type eq 'Array' ) {
                            $type = ref $r;
                            return @$l == @$r if $type eq 'Array';
                            return @$l == $r;
                        }
                        elsif ( $l->can('equals') ) {
                            return $l->equals($r);
                        }
                    }
                    else {
                        $type = ref $r;
                        if ($type) {
                            return @$r == $l if $type eq 'ARRAY';
                            return $r->equals($l) if $r->can('equals');
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
