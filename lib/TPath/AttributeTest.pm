package TPath::AttributeTest;

# ABSTRACT: compares an attribute value to another value

=head1 DESCRIPTION

Implements predicates such as C<//foo[@a < @b]> or C<ancestor::*[@bar = 1]>. That is, predicates
where an attribute is tested against some value.

All attributes are read-only as they should not change after construction. The C<func> attribute
is 

This class if for internal consumption only.

=cut

use feature qw(switch);
use Scalar::Util qw(looks_like_number);
use MooseX::SingletonMethod;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=method test

The test function applied to the values. This method is constructed in C<BUILD> and
assigned to the attribute test as a singleton method.

Expects a node, a collection, and an index.

=attr op

The comparison operator between the two values.

=cut

has op => ( is => 'ro', isa => 'Str', required => 1 );

=attr left

The left value.

=cut

has left => ( is => 'ro', isa => 'ATArg', writer => '_left', required => 1 );

=attr right

The right value.

=cut

has right => ( is => 'ro', isa => 'ATArg', writer => '_right', required => 1 );

sub BUILD {
    my $self = shift;
    my ( $l, $r ) = $self->_types;
    my $lr = $l . $r;
    my $func;
    for ( $self->op ) {
        when ('=') { $func = $self->_se_func( $l, $r, $lr ) }
        when ('==') { $func = $self->_de_func( $l, $r, $lr ) }
        when ('<=') { $func = $self->_le_func( $l, $r, $lr ) }
        when ('<') { $func = $self->_l_func( $l, $r, $lr ) }
        when ('>=') { $func = $self->_ge_func( $l, $r, $lr ) }
        when ('>') { $func = $self->_g_func( $l, $r, $lr ) }
        when ('!=') { $func = $self->_ne_func( $l, $r, $lr ) }
    }
    $self->add_singleton_method( test => $func );
}

sub filter {
    my ( $self, $c, $i ) = @_;
    return grep { $self->test($_, $c, $i) } @$c;
}

# a bunch of private methods that construct custom test methods

# generate = test
sub _se_func {

    # left type, right type, the conjunction
    my ( $self, $l, $r, $lr ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    # constant functions
    return 0 + $lv == 0 + $rv ? sub { 1 } : sub { 0 }
      if $lr =~ /n[ns]|sn/;
    return "" . $lv eq "" . $rv ? sub { 1 } : sub { 0 }
      if $lr eq 'ss';

    # non-silly functions
    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $n == @$v }
                                default        { return 0 }
                            }
                        }
                        $lv == 0 + $v;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('s') {
            for ($r) {
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $lv eq $v;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('a') {
            for ($r) {
                when ('n') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $n == @$v }
                                default        { return 0 }
                            }
                        }
                        $rv == 0 + $v;
                    };
                }
                when ('s') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $rv eq $v;
                    };
                }
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->apply( $n, $c, $i );
                        my $v2 = $rv->apply( $n, $c, $i );
                        if ( !( defined $v1 && defined $v2 ) ) {
                            return !( $v1 ^ $v2 );
                        }
                        ( $l, $r ) = map { _type($_) } $v1, $v2;
                        $lr = "$l$r";
                        for ($lr) {
                            when ('ss') { return $v1 eq $v2 }
                            when ('nn') { return $v1 == $v2 }
                            when ('na') { return $v1 == @$v2 }
                            when ('an') { return @$v1 == $v2 }
                            when ('aa') { return @$v1 == @$v2 }
                            when ('oo') {
                                my $f = $v1->can('equals');
                                return $f->( $v1, $v2 ) if $f;
                                $f = $v2->can('equals');
                                return $f->( $v2, $v1 ) if $f;
                                return $v1 == $v2;
                            }
                            when (/o./) {
                                my $f = $v1->can('equals');
                                return $f->( $v1, $v2 ) if $f;
                                return 0;
                            }
                            when (/.o/) {
                                my $f = $v2->can('equals');
                                return $f->( $v2, $v1 ) if $f;
                                return 0;
                            }
                            default { return $v1 == $v2 }
                        }
                        return $rv eq $v1;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            confess
"handling of values of type TPath::AttributeTest not yet implemented"
        }
        when ('e') {
            confess
              "handling of values of type TPath::Expression not yet implemented"
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

# generate == test
sub _de_func {
    my $self = shift;
    my ( $lt, $rt ) = $self->_types;
    my $lrt = $lt . $rt;
    return 0 + $_[0]->left == 0 + $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt =~ /n[ns]|sn/;
    return "" . $_[0]->left eq "" . $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt eq 'ss';
}

# generate <= test
sub _le_func {
    my $self = shift;
    my ( $lt, $rt ) = $self->_types;
    my $lrt = $lt . $rt;
    return 0 + $_[0]->left <= 0 + $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt =~ /n[ns]|sn/;
    return "" . $_[0]->left cmp "" . $_[0]->right <= 0 ? sub { 1 } : sub { 0 }
      if $lrt eq 'ss';
}

# generate < test
sub _l_func {

    # left type, right type, the conjunction
    my ( $self, $l, $r, $lr ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;
    ...;
}

# generate != test
sub _ne_func {

    # left type, right type, the conjunction
    my ( $self, $l, $r, $lr ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    # constant functions
    return 0 + $lv != 0 + $rv ? sub { 1 } : sub { 0 }
      if $lr =~ /n[ns]|sn/;
    return "" . $lv ne "" . $rv ? sub { 1 } : sub { 0 }
      if $lr eq 'ss';

    # non-silly functions
    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $n != @$v }
                                default        { return 0 }
                            }
                        }
                        $lv != 0 + $v;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('s') {
            for ($r) {
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $lv ne $v;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('a') {
            for ($r) {
                when ('n') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $n != @$v }
                                default        { return 0 }
                            }
                        }
                        $rv != 0 + $v;
                    };
                }
                when ('s') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $rv ne $v;
                    };
                }
                when ('a') {
                    return sub {

                        # node, collection, index
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->apply( $n, $c, $i );
                        my $v2 = $rv->apply( $n, $c, $i );
                        if ( !( defined $v1 && defined $v2 ) ) {
                            return $v1 ^ $v2;
                        }
                        ( $l, $r ) = map { _type($_) } $v1, $v2;
                        $lr = "$l$r";
                        for ($lr) {
                            when ('ss') { return $v1 ne $v2 }
                            when ('nn') { return $v1 != $v2 }
                            when ('na') { return $v1 != @$v2 }
                            when ('an') { return @$v1 != $v2 }
                            when ('aa') { return @$v1 != @$v2 }
                            when ('oo') {
                                my $f = $v1->can('equals');
                                return $f->( $v1, $v2 ) if $f;
                                $f = $v2->can('equals');
                                return !$f->( $v2, $v1 ) if $f;
                                return $v1 != $v2;
                            }
                            when (/o./) {
                                my $f = $v1->can('equals');
                                return !$f->( $v1, $v2 ) if $f;
                                return 1;
                            }
                            when (/.o/) {
                                my $f = $v2->can('equals');
                                return !$f->( $v2, $v1 ) if $f;
                                return 1;
                            }
                            default { return $v1 == $v2 }
                        }
                        return $rv ne $v1;
                    };
                }
                when ('t') {
                    confess
"handling of values of type TPath::AttributeTest not yet implemented"
                }
                when ('e') {
                    confess
"handling of values of type TPath::Expression not yet implemented"
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            confess
"handling of values of type TPath::AttributeTest not yet implemented"
        }
        when ('e') {
            confess
              "handling of values of type TPath::Expression not yet implemented"
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

# generate >= test
sub _ge_func {

    # left type, right type, the conjunction
    my ( $self, $l, $r, $lr ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;
    ...;
}

# generate > test
sub _g_func {

    # left type, right type, the conjunction
    my ( $self, $l, $r, $lr ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;
    ...;
}

# swap left and right
sub _swap {
    my $self = shift;
    my $v    = $self->left;
    $self->_left( $self->right );
    $self->_right($v);
}

# type left and right
sub _types {
    my $self = shift;
    _type( $self->left ), _type( $self->right );
}

# tests type of argument
sub _type {
    my $arg = shift;
    if ( my $type = ref $arg ) {
        return 'h' if $type eq 'HASH';
        return 'r' if $type eq 'ARRAY';
        return 'a' if $arg->isa('TPath::Attribute');
        return 'e' if $arg->isa('TPath::Expression');
        return 't' if $arg->isa('TPath::AttributeTest');
        return 'o';
    }
    return 'n' if looks_like_number $arg;
    return 's';
}

__PACKAGE__->meta->make_immutable;

1;
