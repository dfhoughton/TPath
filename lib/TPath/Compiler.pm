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

use parent 'Exporter';

use TPath::Expression;
use TPath::Selector;
use TPath::Selector::Id;

our @EXPORT_OK = qw(compile);

=func compile

Takes an AST reference and a L<TPath::Forester> reference and returns a L<TPath::Expression>.

=cut

sub compile {
    treepath(@_);    # function alias
}

sub treepath {
    my ( $ref, $forester ) = @_;
    my @paths;
    for my $p ( @{ $ref->{treepath}{path} } ) {
        push @paths, path( $p, $forester );
    }
    return TPath::Expression->new( f => $forester, selectors => \@paths );
}

sub path {
    my ( $p, $forester ) = @_;
    my @selectors;
    for my $step ( @{ $p->{segment} } ) {
        push @selectors, step( $step, $forester );
    }
    return \@selectors;
}

sub step {
    my ($step) = @_;
    return full(@_) if exists $step->{step}{full};
    return abbreviated(@_);
}

sub full {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

sub abbreviated {
    my ($step) = @_;
    my $abb = $step->{step}{abbreviated};
    return id(@_)   if ref $abb;
    return self(@_) if $abb eq '.';
    return parent(@_);
}

sub id {
    my ($step) = @_;
    return TPath::Selector::Id->new( id => $step->{step}{abbreviated}{id} );
}

sub self {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

sub parent {
    my ( $step, $forester ) = @_;
    croak 'not implemented yet';
}

1;
