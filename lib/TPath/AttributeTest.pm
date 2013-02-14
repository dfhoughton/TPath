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
use namespace::autoclean -also => qr/^_/;

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
    my $func;
    for ( $self->op ) {
        when ('=')  { $func = $self->_se_func }
        when ('==') { $func = $self->_de_func }
        when ('<=') { $func = $self->_le_func }
        when ('<')  { $func = $self->_l_func }
        when ('>=') { $func = $self->_ge_func }
        when ('>')  { $func = $self->_g_func }
        when ('!=') { $func = $self->_ne_func }
    }
    $self->add_singleton_method( test => $func );
}

# a bunch of private methods that construct custom test methods

# generate = test
sub _se_func {
    my $self = shift;
    my ( $lt, $rt ) = $self->_types;
    my $lrt = $lt . $rt;

    # constant functions
    return 0 + $_[0]->left == 0 + $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt =~ /n[ns]|sn/;
    return "" . $_[0]->left eq "" . $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt eq 'ss';

    # non-silly functions
    for ($lt) {
        when ('n') {
            my $n = $self->left + 0;
            my $r = $self->right;
            for ($rt) {
                when ('a') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $r->apply( $n, $c, $i );
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') { return $n == @$v }
                                default        { return 0 }
                            }
                        }
                        $n == 0 + $v;
                    };
                }
                when ('t') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $r->test( $n, $c, $i );
                        return $n == $v;
                    };
                }
                when ('e') {
                    return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my @nodes = $r->select( $n, $i );
                        return $n == @nodes;
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $rt"
                }
            }
        }
        when ('s') {
            my $s = $self->left;
            my $r = $self->right;
            for ($rt) {
                when ('a') { return sub {
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $r->apply( $n, $c, $i );
                        return $s eq $v;
                    };}
                when ('t') { 
                        my ( $self, $n, $c, $i ) = @_;
                        my $v = $r->test( $n, $c, $i );
                        return $n eq $v;
                    }
                when ('e') { }
                default {
                    confess "fatal logic error! unexpected argument type $rt"
                }
            }
        }
        when ('a') {
            for ($rt) {
                when ('n') { }
                when ('s') { }
                when ('a') { }
                when ('t') { }
                when ('e') { }
                default {
                    confess "fatal logic error! unexpected argument type $rt"
                }
            }
        }
        when ('t') {
            for ($rt) {
                when ('n') { }
                when ('s') { }
                when ('a') { }
                when ('t') { }
                when ('e') { }
                default {
                    confess "fatal logic error! unexpected argument type $rt"
                }
            }
        }
        when ('e') {
            for ($rt) {
                when ('n') { }
                when ('s') { }
                when ('a') { }
                when ('t') { }
                when ('e') { }
                default {
                    confess "fatal logic error! unexpected argument type $rt"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $lt" }
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
    my $self = shift;
    my ( $lt, $rt ) = $self->_types;
    my $lrt = $lt . $rt;
    return 0 + $_[0]->left < 0 + $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt =~ /n[ns]|sn/;
    return "" . $_[0]->left cmp "" . $_[0]->right < 0 ? sub { 1 } : sub { 0 }
      if $lrt eq 'ss';
}

# generate != test
sub _ne_func {
    my $self = shift;
    my ( $lt, $rt ) = $self->_types;
    my $lrt = $lt . $rt;
    return 0 + $_[0]->left != 0 + $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt =~ /n[ns]|sn/;
    return "" . $_[0]->left ne "" . $_[0]->right ? sub { 1 } : sub { 0 }
      if $lrt eq 'ss';
}

# generate >= test
sub _ge_func {
    my $self = shift;
    $self->_swap;
    $self->_le_func;
}

# generate > test
sub _g_func {
    my $self = shift;
    $self->_swap;
    $self->_l_func;
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
    $self->_type( $self->left ), $self->_type( $self->right );
}

# tests type of argument
sub _type {
    my $arg = shift;
    if ( ref $arg ) {
        return 'a' if $arg->isa('TPath::Attribute');
        return 'e' if $arg->isa('TPath::Expression');
        return 't' if $arg->isa('TPath::AttributeTest');
    }
    return 'n' if looks_like_number $arg;
    return 's';
}

__PACKAGE__->meta->make_immutable;

1;
