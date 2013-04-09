package TPath::AttributeTest;

# ABSTRACT: compares an attribute value to another value

=head1 DESCRIPTION

Implements predicates such as C<//foo[@a < @b]> or C<ancestor::*[@bar = 1]>. That is, predicates
where an attribute is tested against some value.

This class if for internal consumption only.

=cut

use v5.10;
use Scalar::Util qw(refaddr looks_like_number);
use MooseX::SingletonMethod;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Stringifiable>

=cut

with 'TPath::Stringifiable';

=method test

The test function applied to the values. This method is constructed in C<BUILD> and
assigned to the attribute test as a singleton method.

Expects a node, an index, and a collection.

=attr op

The comparison operator between the two values.

=cut

has op => ( is => 'ro', isa => 'Str', required => 1 );

=attr left

The left value.

=cut

has left => ( is => 'ro', isa => 'ATArg', required => 1 );

=attr right

The right value.

=cut

has right => ( is => 'ro', isa => 'ATArg', required => 1 );

sub BUILD {
    my $self = shift;
    my ( $l, $r ) = $self->_types;
    my $lr = $l . $r;
    my $func;

    # some coderefs to turn operators into functions
    state $ge_n = sub { $_[0] >= $_[1]           or undef };
    state $ge_s = sub { ( $_[0] cmp $_[1] ) >= 0 or undef };
    state $le_n = sub { $_[0] <= $_[1]           or undef };
    state $le_s = sub { ( $_[0] cmp $_[1] ) <= 0 or undef };
    state $g_n  = sub { $_[0] > $_[1]            or undef };
    state $g_s  = sub { ( $_[0] cmp $_[1] ) > 0  or undef };
    state $l_n  = sub { $_[0] < $_[1]            or undef };
    state $l_s  = sub { ( $_[0] cmp $_[1] ) < 0  or undef };
    state $ne_n = sub { $_[0] != $_[1]           or undef };
    state $ne_s = sub { $_[0] ne $_[1]           or undef };

    # construct the appropriate function
    for ( $self->op ) {
        when ('=')  { $func = $self->_e_func( $l, $r, $lr, \&_se ) }
        when ('==') { $func = $self->_e_func( $l, $r, $lr, \&_de ) }
        when ('<=') { $func = $self->_c_func( $l, $r, $lr, $le_s, $le_n ) }
        when ('<')  { $func = $self->_c_func( $l, $r, $lr, $l_s,  $l_n ) }
        when ('>=') { $func = $self->_c_func( $l, $r, $lr, $ge_s, $ge_n ) }
        when ('>')  { $func = $self->_c_func( $l, $r, $lr, $g_s,  $g_n ) }
        when ('!=') { $func = $self->_c_func( $l, $r, $lr, $ne_s, $ne_n ) }
        when ('=~') { $func = $self->_m_func( $r, 1 ) }
        when ('!~') { $func = $self->_m_func( $r, 0 ) }
        when ('|=')  { $func = $self->_i_func( $l, $r, 0 ) }
        when ('=|=') { $func = $self->_i_func( $l, $r, 1 ) }
        when ('=|')  { $func = $self->_i_func( $l, $r, 2 ) }
    }

    # store it
    $self->add_singleton_method( test => $func );
}

# a bunch of private methods that construct custom test methods based on string indices
sub _i_func {

    # type of right value; whether the match is positive (=~)
    my ( $self, $l_type, $r_type, $i_type ) = @_;
    if ( $r_type =~ /n|s/ ) {
        my $v      = $self->right;
        my $s_func = _s_func( $self->left );
        for ($i_type) {
            when (0) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$s_func( $n, $i, $c );
                    my $index = index $lv, $v;
                    return $index == 0 ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$s_func( $n, $i, $c );
                    my $index = index $lv, $v;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                my $lr = length $v;
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$s_func( $n, $i, $c );
                    my $index = index $lv, $v;
                    return $index > -1
                      && $index == length($lv) - $lr ? 1 : undef;
                };
            }
        }
    }
    elsif ( $l_type =~ /n|s/ ) {
        my $v      = $self->left;
        my $s_func = _s_func( $self->right );
        for ($i_type) {
            when (0) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $rv = $self->$s_func( $n, $i, $c );
                    my $index = index $v, $rv;
                    return $index == 0 ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $rv = $self->$s_func( $n, $i, $c );
                    my $index = index $v, $rv;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                my $ll = length $v;
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $rv = $self->$s_func( $n, $i, $c );
                    my $index = index $v, $rv;
                    return $index > -1
                      && $index == $ll - length($rv) ? 1 : undef;
                };
            }
        }
    }
    else {
        my $ls_func = _s_func( $self->left );
        my $rs_func = _s_func( $self->right );
        for ($i_type) {
            when (0) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$ls_func( $n, $i, $c );
                    my $rv = $self->$rs_func( $n, $i, $c );
                    my $index = index $lv, $rv;
                    return $index == 0 ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$ls_func( $n, $i, $c );
                    my $rv = $self->$rs_func( $n, $i, $c );
                    my $index = index $lv, $rv;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                return sub {
                    my ( $self, $n, $i, $c ) = @_;
                    my $lv = $self->$ls_func( $n, $i, $c );
                    my $rv = $self->$rs_func( $n, $i, $c );
                    my $index = index $lv, $rv;
                    return $index > -1
                      && $index == length($lv) - length($rv) ? 1 : undef;
                };
            }
        }
    }
}

# a bunch of private methods that construct custom test methods
sub _m_func {

    # type of right value; whether the match is positive (=~)
    my ( $self, $r_type, $positive ) = @_;
    for ($r_type) {
        when (/n|s/) {
            my $v      = $self->right;
            my $re     = qr/$v/;
            my $s_func = _s_func( $self->left );
            return $positive
              ? sub {
                my ( $self, $n, $i, $c ) = @_;
                my $lv = $self->$s_func( $n, $i, $c );
                $lv =~ $re ? 1 : undef;
              }
              : sub {
                my ( $self, $n, $i, $c ) = @_;
                my $lv = $self->$s_func( $n, $i, $c );
                $lv =~ $re ? undef : 1;
              };
        }
        default {
            my $ls_func = _s_func( $self->left );
            my $rs_func = _s_func( $self->right );
            return $positive
              ? sub {
                my ( $self, $n, $i, $c ) = @_;
                my $lv = $self->$ls_func( $n, $i, $c );
                my $rv = $self->$rs_func( $n, $i, $c );
                $lv =~ /$rv/ ? 1 : undef;
              }
              : sub {
                my ( $self, $n, $i, $c ) = @_;
                my $lv = $self->$ls_func( $n, $i, $c );
                my $rv = $self->$rs_func( $n, $i, $c );
                $lv =~ /$rv/ ? undef : 1;
              };
        }
    }
}

# generates a stringification function for a value
sub _s_func {
    my $v = shift;
    for ( _type($v) ) {
        when ('a') {
            return sub {
                my ( $self, $n, $i, $c ) = @_;
                $v->apply( $n, $i, $c );
            };
        }
        when ('e') {
            return sub {
                my ( $self, $n, $i ) = @_;
                my @c = $v->select( $n, $i );
                join '', @c;
            };
        }
        when ('t') {
            return sub {
                my ( $self, $n, $i, $c ) = @_;
                $v->test( $n, $i, $c );
            };
        }
        when (/[ns]/) {
            return sub { "$v" };
        }
    }
}

# generate = test
sub _e_func {

    # left type, right type, the conjunction, the equality function
    my ( $self, $l, $r, $lr, $ef ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    # constant functions
    return 0 + $lv == 0 + $rv ? sub { 1 } : sub { undef }
      if $lr =~ /n[ns]|sn/;
    return "" . $lv eq "" . $rv ? sub { 1 } : sub { undef }
      if $lr eq 'ss';

    # non-silly functions
    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->apply( $n, $i, $c );
                        return 0 unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $rv == @$v or undef }
                                default { return }
                            }
                        }
                        $lv == $v or undef;
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->test( $n, $i, $c );
                        $lv == $v or undef;
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $n, $i ) = @_;
                        my @c = $rv->select( $n, $i );
                        $lv == @c or undef;
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->apply( $n, $i, $c );
                        return unless defined $v;
                        return $lv eq $v or undef;
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->test( $n, $i, $c );
                        $lv eq $v or undef;
                      }
                }
                when ('e') {
                    my ( undef, $n, $i ) = @_;
                    my @c = $rv->select( $n, $i );
                    $lv eq join( '', @c ) or undef;
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $lv->apply( $n, $i, $c );
                        return unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $rv == @$v or undef }
                                default { return }
                            }
                        }
                        $rv == $v or undef;
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $lv->apply( $n, $i, $c );
                        return unless defined $v;
                        return $rv eq $v or undef;
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->apply( $n, $i, $c );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return $ef->( $v1, $v2 ) or undef;
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->apply( $n, $i, $c );
                        my $v2 = $rv->test( $n, $i, $c );
                        return $ef->( $v1, $v2 ) or undef;
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->apply( $n, $i, $c );
                        my @c = $rv->select( $n, $i );
                        return $ef->( $v1, \@c ) or undef;
                    };
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        return $v1 == $rv or undef;
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        return $v1 eq $rv or undef;
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return $ef->( $v1, $v2 ) or undef;
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        my $v2 = $rv->test( $n, $i, $c );
                        return $v1 == $v2 or undef;
                      }
                }
                when ('e') {
                    my ( undef, $n, $i, $c ) = @_;
                    my $v1 = $lv->test( $n, $i, $c );
                    my @c = $lv->select( $n, $i );
                    return $v1 == @c or undef;
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
                        my ( undef, $n, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return @c == $rv or undef;
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return $rv eq join( '', @c ) or undef;
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return $ef->( \@c, $v2 ) or undef;
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->test( $n, $i, $c );
                        return @c == $v2 or undef;
                      }
                }
                when ('e') {
                    my ( undef, $n, $i ) = @_;
                    my @c1 = $lv->select( $n, $i );
                    my @c2 = $rv->select( $n, $i );
                    return @c1 == @c2 or undef;
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

sub _c_func {

# left type, right type, the conjunction, the string comparison function, the number comparison function
    my ( $self, $l, $r, $lr, $sf, $nf ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    # constant functions
    return $nf->( $lv, $rv ) ? sub { 1 } : sub { undef }
      if $lr =~ /n[ns]|sn/;
    return $sf->( $lv, $rv ) ? sub { 1 } : sub { undef }
      if $lr eq 'ss';

    # non-silly functions
    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->apply( $n, $i, $c );
                        return unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') {
                                    return $nf->( $rv, scalar @$v );
                                }
                                default { return }
                            }
                        }
                        $nf->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->test( $n, $i, $c );
                        $nf->( $lv, $v );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $n, $i ) = @_;
                        my @c = $rv->select( $n, $i );
                        $nf->( $lv, scalar @c );
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->apply( $n, $i, $c );
                        return unless defined $v;
                        return $sf->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $rv->test( $n, $i, $c );
                        $sf->( $lv, $v );
                      }
                }
                when ('e') {
                    my ( undef, $n, $i ) = @_;
                    my @c = $rv->select( $n, $i );
                    $sf->( $lv, join '', @c );
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $lv->apply( $n, $i, $c );
                        return unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') {
                                    return $nf->( scalar @$v, $rv );
                                }
                                default { return }
                            }
                        }
                        $nf->( $v, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v = $lv->apply( $n, $i, $c );
                        return unless defined $v;
                        return $sf->( $v, $rv );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->apply( $n, $i, $c );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return _reduce( $v1, $v2, $sf, $nf, $n, $i, $c );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->apply( $n, $i, $c );
                        my $v2 = $rv->test( $n, $i, $c );
                        return _reduce( $v1, $v2, $sf, $nf, $n, $i, $c );
                      }
                }
                when ('e') {
                    my ( undef, $n, $i, $c ) = @_;
                    my $v1 = $lv->apply( $n, $i, $c );
                    my @c = $rv->select( $n, $i );
                    return _reduce( $v1, \@c, $sf, $nf, $n, $i, $c );
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
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        return $nf->( $v1, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        return $sf->( $v1, $rv );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return _reduce( $v1, $v2, $sf, $nf, $n, $i, $c );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        my $v2 = $rv->test( $n, $i, $c );
                        return $nf->( $v1, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my $v1 = $lv->test( $n, $i, $c );
                        my @c = $rv->select( $n, $i );
                        return $nf->( $v1, scalar @c );
                    };
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
                        my ( undef, $n, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return $nf->( scalar @c, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $n, $i ) = @_;
                        my @c = $lv->select( $n, $i );
                        return $sf->( join( '', @c ), $rv );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->apply( $n, $i, $c );
                        return _reduce( \@c, $v2, $sf, $nf, $n, $i, $c );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $n, $i, $c ) = @_;
                        my @c = $lv->select( $n, $i );
                        my $v2 = $rv->test( $n, $i, $c );
                        return $nf->( scalar @c, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $n, $i ) = @_;
                        my @c1 = $lv->select( $n, $i );
                        my @c2 = $rv->select( $n, $i );
                        return $nf->( scalar @c1, scalar @c2 );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

sub _reduce {
    my ( $v1, $v2, $sf, $nf, $n, $i, $c ) = @_;
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    for ("$l$r") {
        when ('nn') { return $nf->( $v1, $v2 ) }
        when (/[sn]{2}/) { return $sf->( $v1, $v2 ) }
        when ('nh') { return $nf->( $v1,              scalar keys %$v2 ) }
        when ('hn') { return $nf->( scalar keys %$v1, $v2 ) }
        when ('nr') { return $nf->( $v1,              scalar @$v2 ) }
        when ('rn') { return $nf->( scalar @$v1,      $v2 ) }
        when ('sr') { return $sf->( $v1, join '', @$v2 ) }
        when ('rs') { return $sf->( join( '', @$v1 ), $v2 ) }
        when (/[eta].|.[eta]/) {
            my ( $v3, $v4 ) = ( $v1, $v2 );
            for ($l) {
                when ('e') { $v3 = [ $v1->select( $n, $i ) ] }
                when ('t') { $v3 = $v1->test( $n, $i, $c ) }
                when ('a') { $v3 = $v1->apply( $n, $i, $c ) }
            }
            for ($r) {
                when ('e') { $v4 = [ $v2->select( $n, $i ) ] }
                when ('t') { $v4 = $v2->test( $n, $i, $c ) }
                when ('a') { $v4 = $v2->apply( $n, $i, $c ) }
            }
            return _reduce( $v3, $v4, $sf, $nf, $n, $i, $c );
        }
        default { return $sf->( $v1, $v2 ) }
    }
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
        when ('ss') { return $v1 eq $v2  ? 1 : undef }
        when ('nn') { return $v1 == $v2  ? 1 : undef }
        when ('nr') { return $v1 == @$v2 ? 1 : undef }
        when ('rn') { return @$v1 == $v2 ? 1 : undef }
        when ('rr') {
            my @a1 = @$v1;
            my @a2 = @$v2;
            return undef unless @a1 == @a2;
            for my $i ( 0 .. $#a1 ) {
                return undef unless _se( $a1[$i], $a2[$i] );
            }
            return 1;
        }
        when ('hh') {
            my @keys = keys %$v1;
            return undef unless @keys == (keys %$v2);
            for my $k (@keys) {
                my ($o1, $o2) = ($v1->{$k}, $v2->{$k});
                return undef unless _se($o1, $o2);
            }
            return 1;
        }
        when ('oo') {
            my $f = $v1->can('equals');
            return $v1->$f($v2) ? 1 : undef if $f;
            $f = $v2->can('equals');
            return $v2->$f->($v1) ? 1 : undef if $f;
            return refaddr $v1 == refaddr $v2 ? 1 : undef;
        }
        when (/o./) {
            my $f = $v1->can('equals');
            return $v1->$f->($v2) ? 1 : undef if $f;
            return undef;
        }
        when (/.o/) {
            my $f = $v2->can('equals');
            return $v2->$f($v1) ? 1 : undef if $f;
            return undef;
        }
        default { return undef }
    }
}

# double equals
sub _de {
    my ( $v1, $v2 ) = @_;
    if ( !( defined $v1 && defined $v2 ) ) {
        return !( defined $v1 || defined $v2 ) ? 1 : undef;
    }
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    my $lr = "$l$r";
    for ($lr) {
        when ('ss') { return $v1 eq $v2       ? 1 : undef }
        when ('nn') { return $v1 == $v2       ? 1 : undef }
        when ('hn') { return keys %$v1 == $v2 ? 1 : undef }
        when ('nh') { return $v1 == keys %$v2 ? 1 : undef }
        when ('nr') { return $v1 == @$v2      ? 1 : undef }
        when ('rn') { return @$v1 == $v2      ? 1 : undef }
        default {
            return ( refaddr $v1 || 0 ) == ( refaddr $v2 || 0 )
              ? 1
              : undef;
        }
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

sub to_string {
    my $self = shift;
    $self->_stringify( $self->left ) . ' '
      . $self->op . ' '
      . $self->_stringify( $self->right );
}

__PACKAGE__->meta->make_immutable;

1;
