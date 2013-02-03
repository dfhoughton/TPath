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

our @EXPORT_OK = qw(compile);

=method compile

Takes an AST reference and a L<TPath::Forester> reference and returns a L<TPath::Expression>.

=cut

sub compile {
    my ( $ref, $forester ) = @_;
    croak 'unfinished';
}

1;
