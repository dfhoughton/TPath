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
        when ('=') { $func = $self->_e_func( $l, $r, $lr, \&_se ) }
        when ('==') { $func = $self->_e_func( $l, $r, $lr, \&_de ) }
        when ('<=') { $func = $self->_le_func( $l, $r, $lr ) }
        when ('<') { $func = $self->_l_func( $l, $r, $lr ) }
        when ('>=') { $func = $self->_ge_func( $l, $r, $lr ) }
        when ('>') { $func = $self->_g_func( $l, $r, $lr ) }
        when ('!=') { $func = $self->_ne_func( $l, $r, $lr ) }
    }
    $self->add_singleton_method( test => $func );
}

# a bunch of private methods that construct custom test methods

# generate = test
sub _e_func {

    # left type, right type, the conjunction, the equality function
    my ( $self, $l, $r, $lr, $ef ) = @_;

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
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $rv == @$v }
                                default        { return 0 }
                            }
                        }
                        $lv == 0 + $v;
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->test( $n, $c, $i );
                        $lv == $v;
                      }
                }
                when ('e') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @c = $rv->select( $n, $i );
                        $lv == @c;
                      }
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
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $lv eq $v;
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $rv->test( $n, $c, $i );
                        $lv eq $v;
                      }
                }
                when ('e') {
                    my ( $self, $n, $c, $i ) = @_;
                    my @c = $rv->select( $n, $i );
                    $lv eq join '', @c;
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
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $rv == @$v }
                                default        { return 0 }
                            }
                        }
                        $rv == 0 + $v;
                    };
                }
                when ('s') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $lv->apply( $n, $c, $i );
                        return 0 unless defined $v;
                        return $rv eq $v;
                    };
                }
                when ('a') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->apply( $n, $c, $i );
                        my $v2 = $rv->apply( $n, $c, $i );
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->apply( $n, $c, $i );
                        my $v2 = $rv->test( $n, $c, $i );
                        return $ef->( $v1, $v2 );
                      }
                }
                when ('e') {
                    my ( $self, $n, $c, $i ) = @_;
                    my $v1 = $lv->apply( $n, $c, $i );
                    my @c = $rv->select( $n, $i );
                    return $ef->( $v1, \@c );
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->test( $n, $c, $i );
                        return $v1 == $rv;
                    };
                }
                when ('s') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->test( $n, $c, $i );
                        return $v1 eq $rv;
                    };
                }
                when ('a') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->test( $n, $c, $i );
                        my $v2 = $rv->apply( $n, $c, $i );
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v1 = $lv->test( $n, $c, $i );
                        my $v2 = $rv->test( $n, $c, $i );
                        return $v1 == $v2;
                      }
                }
                when ('e') {
                    my ( $self, $n, $c, $i ) = @_;
                    my $v1 = $lv->test( $n, $c, $i );
                    my @c = $lv->select( $n, $i );
                    return $v1 == @c;
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('e') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return @c == $rv;
                    };
                }
                when ('s') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return $rv eq join '', @c;
                    };
                }
                when ('a') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->apply( $n, $c, $i );
                        return $ef->( \@c, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->test( $n, $c, $i );
                        return @c == $v2;
                      }
                }
                when ('e') {
                    my ( $self, $n, $c, $i ) = @_;
                    my @c1 = $lv->select( $n, $i );
                    my @c2 = $rv->select( $n, $i );
                    return @c1 == @c2;
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
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
                    ...;
                }
                when ('e') {
                    ...;
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
                    ...;
                }
                when ('e') {
                    ...;
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
                when ('r') {
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
                            when ('nr') { return $v1 != @$v2 }
                            when ('rn') { return @$v1 != $v2 }
                            when ('rr') { return @$v1 != @$v2 }
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
                    ...;
                }
                when ('e') {
                    ...;
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            ...;
        }
        when ('e') {
            ...;
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

# single equals
sub _se {
    my ( $v1, $v2 ) = @_;

    if ( !( defined $v1 && defined $v2 ) ) {
        return !( $v1 ^ $v2 );
    }
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    my $lr = "$l$r";
    for ($lr) {
        when ('ss') { return $v1 eq $v2 }
        when ('nn') { return $v1 == $v2 }
        when ('nr') { return $v1 == @$v2 }
        when ('rn') { return @$v1 == $v2 }
        when ('rr') { return @$v1 == @$v2 }
        when ('oo') {
            my $f = $v1->can('equals');
            return $f->( $v1, $v2 ) if $f;
            $f = $v2->can('equals');
            return $f->( $v2, $v1 ) if $f;
            return refaddr $v1 eq refaddr $v2;
        }
        when (/o./) {
            my $f = $v1->can('equals');
            return $f->( $v1, $v2 ) if $f;
            return $v1 eq $v2;
        }
        when (/.o/) {
            my $f = $v2->can('equals');
            return $f->( $v2, $v1 ) if $f;
            return $v1 eq $v2;
        }
        default { return $v1 eq $v2 }
    }
}

# double equals
sub _de {
    my ( $v1, $v2 ) = @_;

    if ( !( defined $v1 && defined $v2 ) ) {
        return !( defined $v1 || defined $v2 );
    }
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    my $lr = "$l$r";
    for ($lr) {
        when ('ss') { return $v1 eq $v2 }
        when ('nn') { return $v1 == $v2 }
        when ('hn') { return keys %$v1 == $v2 }
        when ('nh') { return $v1 == keys %$v2 }
        when ('hh') {
            my @keys = keys %$v1;
            return 0 unless @keys == keys %$v2;
            for my $k (@keys) {
                return 0 unless exists $v2->{$k};
                my $o1 = $v1->{$k};
                my $o2 = $v2->{$k};
                return 0 unless _de( $o1, $o2 );
            }
            return 1;
        }
        when ('na') { return $v1 == @$v2 }
        when ('an') { return @$v1 == $v2 }
        when ('aa') {
            return 0 unless @$v1 == @$v2;
            for my $i ( 0 .. $#$v1 ) {
                my $o1 = $v1->[$i];
                my $o2 = $v2->[$i];
                return 0 unless _de( $o1, $o2 );
            }
            return 1;
        }
        when ('oo') {
            my $f = $v1->can('equals');
            return $f->( $v1, $v2 ) if $f;
            $f = $v2->can('equals');
            return $f->( $v2, $v1 ) if $f;
            return refaddr $v1 eq refaddr $v2;
        }
        when (/o./) {
            my $f = $v1->can('equals');
            return $f->( $v1, $v2 ) if $f;
            return $v1 eq $v2;
        }
        when (/.o/) {
            my $f = $v2->can('equals');
            return $f->( $v2, $v1 ) if $f;
            return $v1 eq $v2;
        }
        default { return $v1 eq $v2 }
    }
}

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
