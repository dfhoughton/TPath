package TPath::Attribute;

# ABSTRACT: handles evaluating an attribute for a particular node

=head1 DESCRIPTION

For use in compiled TPath expressions. Not for external consumption.

=cut

use v5.10;
use Moose;
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

=attr code

The actual code reference invoked when C<apply> is called.

=cut

has code => ( is => 'ro', isa => 'CodeRef', required => 1 );

=method apply

Expects a node, and index, and a collection. Returns some value.

=cut

sub apply {
    my ( $self, $ctx ) = @_;
    my @args = ($ctx);

    # invoke all code to reify arguments
    for my $a ( @{ $self->args } ) {
        my $value = $a;
        my $type  = ref $a;
        if ( $type && $type !~ /ARRAY|HASH/ ) {
            if ( $a->isa('TPath::Attribute') ) {
                $value = $a->apply($ctx);
            }
            elsif ( $a->isa('TPath::AttributeTest') ) {
                $value = $a->test($ctx);
            }
            elsif ( $a->isa('TPath::Expression') ) {
                $value =
                  [ map { $_->n } @{ $a->_select( $ctx, 0 ) } ];
            }
            elsif ( $a->does('TPath::Test') ) {
                $value = $a->test($ctx);
            }
            else { confess 'unknown argument type: ' . ( ref $a ) }
        }
        push @args, $value;
    }
    $self->code->( $ctx->i->f, @args );
}

=method to_num

Basically an alias for C<apply>. Required by L<TPath::Numifier>.

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
    my $s    = '@' . $self->_stringify_label( $self->name );
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
