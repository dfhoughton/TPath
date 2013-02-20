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

use TPath::Attribute;
use TPath::AttributeTest;
use TPath::Expression;
use TPath::Predicate::Index;
use TPath::Selector;
use TPath::Selector::Id;
use TPath::Selector::Parent;
use TPath::Selector::Self;
use TPath::Selector::Test::Anywhere;
use TPath::Selector::Test::AnywhereMatch;
use TPath::Selector::Test::AnywhereTag;
use TPath::Selector::Test::AxisMatch;
use TPath::Selector::Test::AxisTag;
use TPath::Selector::Test::AxisWildcard;
use TPath::Selector::Test::Child;
use TPath::Selector::Test::ChildMatch;
use TPath::Selector::Test::ChildTag;
use TPath::Selector::Test::ClosestMatch;
use TPath::Selector::Test::ClosestTag;
use TPath::Selector::Test::Root;
use TPath::Selector::Test::RootAxisMatch;
use TPath::Selector::Test::RootAxisTag;
use TPath::Selector::Test::RootAxisWildcard;
use TPath::Selector::Test::RootMatch;
use TPath::Selector::Test::RootTag;

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
    return TPath::Expression->new( f => $forester, _selectors => \@paths );
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
                        return TPath::Selector::Test::RootAxisWildcard->new(
                            axis => $axis )
                          if $axis;
                        return TPath::Selector::Test::Root->new(
                            predicates => \@predicates );
                    }
                    return TPath::Selector::Test::AxisWildcard->new(
                        axis       => $axis,
                        predicates => \@predicates,
                    ) if $axis;
                    return TPath::Selector::Test::AxisWildcard->new(
                        predicates => \@predicates, );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return TPath::Selector::Test::Anywhere->new(
                        first      => $first,
                        predicates => \@predicates
                    );
                }
                when ('/>') { croak '/>* disallowed' }
            }
        }
        when ('specific') {
            for ($sep) {
                when ('/') {
                    if ($first) {
                        return TPath::Selector::Test::RootAxisTag->new(
                            axis       => $axis,
                            tag        => $val,
                            predicates => \@predicates,
                        ) if $axis;
                        return TPath::Selector::Test::RootTag->new(
                            tag        => $val,
                            predicates => \@predicates,
                        );
                    }
                    return TPath::Selector::Test::AxisTag(
                        axis       => $axis,
                        tag        => $val,
                        predicates => \@predicates,
                    ) if $axis;
                    return TPath::Selector::Test::ChildTag->new(
                        tag        => $val,
                        predicates => \@predicates,
                    );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return TPath::Selector::Test::AnywhereTag->new(
                        tag        => $val,
                        first      => $first,
                        predicates => \@predicates,
                    );
                }
                when ('/>') {
                    croak 'axes disallowed with /> separator' if defined $axis;
                    return TPath::Selector::Test::ClosestTag->new(
                        tag        => $val,
                        predicates => \@predicates,
                    );
                }
                default {
                    return TPath::Selector::Test::AxisTag(
                        axis       => $axis,
                        tag        => $val,
                        predicates => \@predicates,
                    ) if $axis;
                    return TPath::Selector::Test::ChildTag->new(
                        tag        => $val,
                        predicates => \@predicates,
                    );
                }
            }
        }
        when ('pattern') {
            my $rx = qr/$val/;
            for ($sep) {
                when ('/') {
                    if ($first) {
                        return TPath::Selector::Test::RootAxisMatch->new(
                            axis       => $axis,
                            rx         => $rx,
                            predicates => \@predicates,
                        ) if $axis;
                        return TPath::Selector::Test::RootMatch->new(
                            rx         => $rx,
                            predicates => \@predicates,
                        );
                    }
                    return TPath::Selector::Test::AxisMatch(
                        axis       => $axis,
                        rx         => $rx,
                        predicates => \@predicates,
                    ) if $axis;
                    return TPath::Selector::Test::ChildMatch->new(
                        rx         => $rx,
                        predicates => \@predicates,
                    );
                }
                when ('//') {
                    croak 'axes disallowed with // separator' if defined $axis;
                    return TPath::Selector::Test::AnywhereMatch->new(
                        rx         => $rx,
                        first      => $first,
                        predicates => \@predicates,
                    );
                }
                when ('/>') {
                    croak 'axes disallowed with /> separator' if defined $axis;
                    return TPath::Selector::Test::ClosestMatch->new(
                        rx         => $rx,
                        predicates => \@predicates,
                    );
                }
                default {
                    return TPath::Selector::Test::AxisMatch(
                        axis       => $axis,
                        rx         => $rx,
                        predicates => \@predicates,
                    ) if $axis;
                    return TPath::Selector::Test::ChildMatch->new(
                        rx         => $rx,
                        predicates => \@predicates,
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
    return TPath::Predicate::Index->new( idx => $idx ) if defined $idx;
    my $op = $predicate->{condition}{operator};
    return condition( $predicate, $forester, $op ) if defined $op;
    my $at = $predicate->{attribute_test};
    return attribute_test( $at, $forester ) if defined $at;
    return attribute( $predicate->{attribute}, $forester );
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
    return TPath::Attribute->new(
        name => $name,
        args => \@args,
        code => $code
    );
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
    return TPath::AttributeTest->new(
        op    => $op,
        left  => $left,
        right => $right
    );
}

sub condition {
    my ( $predicate, $forester, $op ) = @_;
    my $args = $predicate->{condition}{args};
    my @args;
    push @args, arg( $_, $forester ) for @$args;
    for ($op) {
        when ('!') { return TPath::Test::Not->new( t     => $args[0] ) }
        when ('&') { return TPath::Test::And->new( tests => \@args ) }
        when ('||') { return TPath::Test::Or->new( tests => \@args ) }
        when ('^') { return TPath::Test::XOr->new( tests => \@args ) }
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
    return TPath::Selector::Id->new( id => $step->{step}{abbreviated}{id} );
}

sub self {
    my ( $first, $step, $forester ) = @_;
    return TPath::Selector::Test::Root->new if $first && $step->{separator};
    return TPath::Selector::Self->new;
}

sub parent {
    my ( $first, $step ) = @_;
    croak 'root has no parent' if $first && $step->{separator};
    return TPath::Selector::Parent->new;
}

1;
