package TPath::Compiler;

# ABSTRACT: takes ASTs and returns compiled L<TPath::Expression> objects

=head1 DESCRIPTION

This module is a ghetto for the code that converts an AST produced by L<TPath::Grammar>
into L<TPath::Expression> objects. It's really not something you should be messing
around with unless you're working on TPath itself.

=cut

use strict;
use warnings;
use Carp;
use feature 'switch';

use parent 'Exporter';

use aliased 'TPath::Attribute';
use aliased 'TPath::AttributeTest';
use aliased 'TPath::Expression';
use aliased 'TPath::Predicate::Index';
use aliased 'TPath::Predicate::Attribute'     => 'PA';
use aliased 'TPath::Predicate::AttributeTest' => 'PAT';
use aliased 'TPath::Predicate::Boolean'       => 'PB';
use aliased 'TPath::Predicate::Expression'    => 'PE';
use aliased 'TPath::Selector';
use aliased 'TPath::Selector::Id';
use aliased 'TPath::Selector::Parent';
use aliased 'TPath::Selector::Self';
use aliased 'TPath::Selector::Test::Anywhere';
use aliased 'TPath::Selector::Test::AnywhereMatch';
use aliased 'TPath::Selector::Test::AnywhereTag';
use aliased 'TPath::Selector::Test::AxisMatch';
use aliased 'TPath::Selector::Test::AxisTag';
use aliased 'TPath::Selector::Test::AxisWildcard';
use aliased 'TPath::Selector::Test::ChildMatch';
use aliased 'TPath::Selector::Test::ChildTag';
use aliased 'TPath::Selector::Test::ClosestMatch';
use aliased 'TPath::Selector::Test::ClosestTag';
use aliased 'TPath::Selector::Test::Root';
use aliased 'TPath::Selector::Test::RootAxisMatch';
use aliased 'TPath::Selector::Test::RootAxisTag';
use aliased 'TPath::Selector::Test::RootAxisWildcard';
use aliased 'TPath::Selector::Test::RootMatch';
use aliased 'TPath::Selector::Test::RootTag';
use aliased 'TPath::Test::And';
use aliased 'TPath::Test::Not';
use aliased 'TPath::Test::Or';
use aliased 'TPath::Test::XOr';

# use aliased 'TPath::Selector::Test::Child';

our @EXPORT_OK = qw(compile);

=func compile

Takes an AST reference and a L<TPath::Forester> reference and returns a L<TPath::Expression>.

=cut

sub compile { treepath(@_) }

sub treepath {
    my ( $ref, $forester ) = @_;
    my @paths;
    for my $p ( @{ $ref->{treepath}{path} } ) {
        push @paths, path( $p, $forester );
    }
    return Expression->new( f => $forester, _selectors => \@paths );
}

sub path {
    my ( $p, $forester ) = @_;
    my @selectors;
    for my $step ( @{ $p->{segment} } ) {
        push @selectors, step( !@selectors, $step, $forester );
    }
    return \@selectors;
}

sub step {
    my ( undef, $step ) = @_;
    return full(@_) if exists $step->{step}{full};
    return abbreviated(@_);
}

sub full {
    my ( $first, $step, $forester ) = @_;
    my @predicates = predicates( $step->{step}{predicate}, $forester );
    my $sep        = $step->{separator};
    my $type       = $step->{step}{full}{forward};
    my $axis       = $step->{step}{full}{axis};
    my ( $key, $val ) = each %$type;
    for ($key) {
        when ('wildcard') {
            for ($sep) {
                when ('/') {
                    if ($first) {
                        return RootAxisWildcard->new( axis => $axis ) if $axis;
                        return Root->new( predicates => \@predicates );
                    }
                    return AxisWildcard->new(
                        axis       => $axis,
                        predicates => \@predicates
                    ) if $axis;
                    return AxisWildcard->new( predicates => \@predicates );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return Anywhere->new(
                        first      => $first,
                        predicates => \@predicates
                    );
                }
                when ('/>') { croak '/>* disallowed' }
                default {
                    return AxisWildcard->new(
                        axis       => $axis,
                        predicates => \@predicates
                    ) if $axis;
                    return AxisWildcard->new( predicates => \@predicates );
                }
            }
        }
        when ('specific') {
            for ($sep) {
                when ('/') {
                    if ($first) {
                        return RootAxisTag->new(
                            axis       => $axis,
                            tag        => $val,
                            predicates => \@predicates
                        ) if $axis;
                        return RootTag->new(
                            tag        => $val,
                            predicates => \@predicates
                        );
                    }
                    return AxisTag->new(
                        axis       => $axis,
                        tag        => $val,
                        predicates => \@predicates
                    ) if $axis;
                    return ChildTag->new(
                        tag        => $val,
                        predicates => \@predicates
                    );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return AnywhereTag->new(
                        tag        => $val,
                        first      => $first,
                        predicates => \@predicates
                    );
                }
                when ('/>') {
                    croak 'axes disallowed with /> separator' if defined $axis;
                    return ClosestTag->new(
                        tag        => $val,
                        predicates => \@predicates
                    );
                }
                default {
                    return AxisTag->new(
                        axis       => $axis,
                        tag        => $val,
                        predicates => \@predicates
                    ) if $axis;
                    return ChildTag->new(
                        tag        => $val,
                        predicates => \@predicates
                    );
                }
            }
        }
        when ('pattern') {
            my $rx = qr/$val/;
            for ($sep) {
                when ('/') {
                    if ($first) {
                        return RootAxisMatch->new(
                            axis       => $axis,
                            rx         => $rx,
                            predicates => \@predicates
                        ) if $axis;
                        return RootMatch->new(
                            rx         => $rx,
                            predicates => \@predicates
                        );
                    }
                    return AxisMatch->new(
                        axis       => $axis,
                        rx         => $rx,
                        predicates => \@predicates
                    ) if $axis;
                    return ChildMatch->new(
                        rx         => $rx,
                        predicates => \@predicates
                    );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return TPath::Selector::Test::AnywhereMatch->new(
                        rx         => $rx,
                        first      => $first,
                        predicates => \@predicates
                    );
                }
                when ('/>') {
                    croak 'axes disallowed with /> separator' if defined $axis;
                    return ClosestMatch->new(
                        rx         => $rx,
                        predicates => \@predicates
                    );
                }
                default {
                    return AxisMatch->new(
                        axis       => $axis,
                        rx         => $rx,
                        predicates => \@predicates
                    ) if $axis;
                    return ChildMatch->new(
                        rx         => $rx,
                        predicates => \@predicates
                    );
                }
            }
        }
    }
}

sub predicates {
    my ( $predicates, $forester ) = @_;
    return () unless $predicates;
    my @predicates = map { predicate( $_, $forester ) } @$predicates;
    if ( 1 < grep { $_->isa('TPath::Predicate::Index') } @predicates ) {
        croak 'a step may only have one index predicate';
    }
    return @predicates;
}

sub predicate {
    my ( $predicate, $forester ) = @_;
    my $idx = $predicate->{idx};
    return Index->new( idx => $idx ) if defined $idx;
    my $op = $predicate->{condition}{operator};
    return PB->new( t => condition( $predicate, $forester, $op ) )
      if defined $op;
    my $at = $predicate->{attribute_test};
    return PAT->new( at => attribute_test( $at, $forester ) ) if defined $at;
    return PA->new( a => attribute( $predicate->{attribute}, $forester ) );
}

sub attribute {
    my ( $attribute, $forester ) = @_;
    my @args;
    my $args = $attribute->{args};
    if ( defined $args ) {
        push @args, arg( $_, $forester ) for @{ $args->{arg} };
    }
    my $name = $attribute->{aname};
    my $code = $forester->_attributes->{$name};
    return Attribute->new( name => $name, args => \@args, code => $code );
}

sub arg {
    my ( $arg, $forester ) = @_;
    my $v = $arg->{v};
    return $v if defined $v;
    return attribute( $arg, $forester ) if exists $arg->{aname};
    my $a = $arg->{attribute};
    return attribute( $a, $forester ) if defined $a;
    return treepath( $arg, $forester ) if exists $arg->{treepath};
    my $at = $arg->{attribute_test};
    return attribute_test( $at, $forester ) if defined $at;
    my $op = $arg->{condition}{operator};
    return condition( $arg, $forester, $op ) if defined $op;
    croak
      'fatal compilation error; could not compile parsable argument with keys '
      . ( join ', ', sort keys %$arg );
}

sub attribute_test {
    my ( $at, $forester ) = @_;
    my $op    = $at->{cmp};
    my @args  = @{ $at->{args} };
    my $left  = arg( $args[0], $forester );
    my $right = arg( $args[1], $forester );
    return AttributeTest->new( op => $op, left => $left, right => $right );
}

sub condition {
    my ( $predicate, $forester, $op ) = @_;
    my $args = $predicate->{condition}{args};
    my @args;
    push @args, arg( $_, $forester ) for @$args;
    for ($op) {
        when ('!') { return Not->new( t     => $args[0] ) }
        when ('&') { return And->new( tests => \@args ) }
        when ('||') { return Or->new( tests => \@args ) }
        when ('^') { return XOr->new( tests => \@args ) }
    }
}

sub abbreviated {
    my ( undef, $step ) = @_;
    my $abb = $step->{step}{abbreviated};
    return id(@_)   if ref $abb;
    return self(@_) if $abb eq '.';
    return parent(@_);
}

sub id {
    my ( undef, $step ) = @_;
    return Id->new( id => $step->{step}{abbreviated}{id} );
}

sub self {
    my ( $first, $step, $forester ) = @_;
    return Root->new if $first && $step->{separator};
    return Self->new;
}

sub parent {
    my ( $first, $step ) = @_;
    croak 'root has no parent' if $first && $step->{separator};
    return Parent->new;
}

1;
