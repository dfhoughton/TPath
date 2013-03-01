package TPath::Attribute;

# ABSTRACT: handles evaluating an attribute for a particular node

=head1 DESCRIPTION

For use in compiled TPath expressions. Not for external consumption.

=cut

use feature qw(switch);
use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test>

=cut

with 'TPath::Test';

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

Expects a node, a collection, and an index. Returns some value.

=cut

sub apply {
    my ( $self, $n, $c, $i ) = @_;
    my @args = ( $n, $c, $i );

    # invoke all code to reify arguments
    for my $a ( @{ $self->args } ) {
        my $value = $a;
        my $type = ref $a;
        if ( $type && $type !~ /ARRAY|HASH/ ) {
            if ( $a->isa('TPath::Attribute') ) {
                $value = $a->apply( $n, $c, $i );
            }
            elsif ( $a->isa('TPath::AttributeTest') ) {
                $value = $a->test( $n, $c, $i );
            }
            elsif ( $a->isa('TPath::Expression') ) {
                $value = [ $a->select( $n, $i ) ];
            }
            elsif ( $a->does('TPath::Test') ) {
                $value = $a->test( $n, $c, $i );
            }
            else { confess 'unknown argument type: ' . ( ref $a ) }
        }
        push @args, $value;
    }
    $self->code->( $i->f, @args );
}

# required by TPath::Test
sub test {
    my ( $self, $n, $c, $i ) = @_;
    defined $self->apply( $n, $c, $i );
}

__PACKAGE__->meta->make_immutable;

1;
