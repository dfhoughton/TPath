package TPath::Math;

# ABSTRACT: handles the arithmetic in C<//foo[1 + @bar = @quux]>

use Moose;
use List::Util qw(reduce);
use TPath::TypeConstraints;
use namespace::autoclean;

with qw(TPath::Numifiable);

has operator => ( is => 'ro', isa => 'Str', required => 1 );

has func => ( is => 'ro', isa => 'CodeRef', writer => '_func' );

has args => ( is => 'ro', isa => 'ArrayRef[MathArg]' );

sub BUILD {
    my $self = shift;
    my $sub  = eval 'sub { reduce { $a ' . $self->operator . ' $b } @_ }';
    $self->_func($sub);
}

sub to_string {
    my ($self, $in_parens) = @_;
    my $s = $in_parens ? '' : '(';
    my $non_first = 0;
    for my $arg (@{$self->args}) {
        $s .= $self->operator if $non_first++;
        $s .= ' ';
        $s .= ref $arg ? $arg->to_string : $arg;
        $s .= ' ';
    }
    if ($in_parens) {
        $s =~ s/^\s+|\s+$//g;
    } else {
        $s .= ')';
    }
    return $s;
}

sub to_num {
    my ($self, $ctx) = @_;
    my @args = map { ref $_ ? $_->to_num($ctx) : $_ } @{$self->args};
    return $self->func->(@args);
}

1;
