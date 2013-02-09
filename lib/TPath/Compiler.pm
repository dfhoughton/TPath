package TPath::Compiler;

# ABSTRACT : takes ASTs and returns compiled TPath::Expression objects

=head1 DESCRIPTION

This module is a ghetto for the code that converts an AST produced by L<TPath::Grammar>
into L<TPath::Expression> objects. It's really not something you should be messing
around with unless you're workign on TPath itself.

=cut

use strict;
use warnings;
use Carp;

use parent 'Exporter';

use TPath::Expression;
use TPath::Selector;
use TPath::Selector::Id;

our @EXPORT_OK = qw(compile);

=method compile

Takes an AST reference and a L<TPath::Forester> reference and returns a L<TPath::Expression>.

=cut

sub compile {
    goto &compile_treepath;    # function alias
}

sub compile_treepath {
    my ( $ref, $forester ) = @_;
    my @paths;
    for my $p ( @{ $ref->{treepath}{path} } ) {
        push @paths, compile_path( $p, $forester );
    }
    return TPath::Expression->new( f => $forester, selectors => \@paths );
}

sub compile_path {
    my ( $p, $forester ) = @_;
    my @selectors;
    for my $step ( @{ $p->{segment} } ) {
        push @selectors, compile_step( $step, $forester );
    }
    return \@selectors;
}

sub compile_step {
    my ($step) = @_;
    goto &compile_full if exists $step->{step}{full};
    goto &compile_abbreviated;
}

sub compile_full {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

sub compile_abbreviated {
    my ($step) = @_;
    my $abb = $step->{step}{abbreviated};
    goto &compile_id   if ref $abb;
    goto &compile_self if $abb eq '.';
    goto &compile_parent;
}

sub compile_id {
    my ($step) = @_;
    return TPath::Selector::Id->new( id => $step->{step}{abbreviated}{id} );
}

sub compile_self {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

sub compile_parent {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

1;
