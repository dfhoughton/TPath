package TPath::Attribute;

# ABSTRACT: handles evaluating an attribute for a particular node

=head1 DESCRIPTION

For use in compiled TPath expressions. Not for external consumption.

=cut

use v5.10;
no if $] >= 5.018, warnings => "experimental";

use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test>, L<TPath::Stringifiable>

=cut

with qw(TPath::Test TPath::Numifiable);

=attr name

The name of the attribute. E.g., in C<@foo>, C<foo>.

=cut

has name => ( is => 'ro', isa => 'Str', required => 1 );

=attr args

The arguments the attribute takes, if any.

=cut

has args => ( is => 'ro', isa => 'ArrayRef', required => 1 );

# caches results of reflective code for processing args
has _arg_subs => (
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    lazy    => 1,
    builder => '_build_arg_subs'
);

has _expr => ( is => 'rw', isa => 'TPath::Expression', weak_ref => 1 )
  ;

=attr code

The actual code reference invoked when C<apply> is called.

=cut

has code => ( is => 'ro', isa => 'CodeRef', required => 1 );

=attr autoloaded

Whether the attribute was generated by an auto-loading mechanism.

=cut

has autoloaded => ( is => 'ro', isa => 'Bool', default => 0 );

=method apply

Expects a node, and index, and a collection. Returns some value.

=cut

sub apply {
    my ( $self, $ctx ) = @_;
    $ctx->expression( $self->_expr );
    my @args = ($ctx);

    # invoke all code to reify arguments
    push @args, $_->($ctx) for @{ $self->_arg_subs };
    $self->code->( $ctx->i->f, @args );
}

sub _build_arg_subs {
    my $self = shift;
    my @codes;
    for my $a ( @{ $self->args } ) {
        my $type = ref $a;
        my $sub;
        if ( $type && $type !~ /ARRAY|HASH/ ) {
            if ( $a->isa('TPath::Attribute') ) {
                $sub = sub { $a->apply(shift) };
            }
            elsif ( $a->isa('TPath::Concatenation') ) {
                $sub = sub { $a->concatenate(shift) };
            }
            elsif ( $a->isa('TPath::AttributeTest') ) {
                $sub = sub { $a->test(shift) };
            }
            elsif ( $a->isa('TPath::Expression') ) {
                $sub = sub {
                    [ map { $_->n } @{ $a->_select( shift, 0 ) } ];
                };
            }
            elsif ( $a->does('TPath::Test') ) {
                $sub = sub { $a->test(shift) };
            }
            else { confess "unknown argument type: $type" }
        }
        else {
            $sub = sub { $a };
        }
        push @codes, $sub;
    }
    return \@codes;
}

=method to_num

Basically an alias for C<apply>. Required by L<TPath::Numifiable>.

=cut

sub to_num {
    my ( $self, $ctx ) = @_;
    my $val = $self->apply($ctx);
    for ( ref $val ) {
        when ('ARRAY') { return scalar @$val }
        when ('HASH')  { return scalar keys %$val }
        default        { return 0 + $val }
    }
}

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    defined $self->apply($ctx);
}

sub to_string {
    my $self = shift;
    my $s    = '@';
    $s .= ':' if $self->autoloaded;
    $s .= $self->_stringify_label( $self->name );
    my @args = @{ $self->args };
    if (@args) {
        $s .= '(' . $self->_stringify( $args[0] );
        for my $arg ( @args[ 1 .. $#args ] ) {
            $s .= ', ' . $self->_stringify($arg);
        }
        $s .= ')';
    }
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;
