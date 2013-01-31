package TPath::Attribute;

# ABSTRACT : handles evaluating an attribute for a particular node

=head1 DESCRIPTION

For use in compiled TPath expressions. Not for external consumption.

=cut

use feature qw(switch);
use Moose;
use namespace::autoclean;

has name => ( is => 'ro', isa => 'Str', required => 1 );

has args => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

sub apply {
    my ( $self, $n, $c, $i ) = @_;
    my $method = $self->name;
    my @args = ( $n, $c, $i );

    # invoke all code to reify arguments
    for my $a ( @{ $self->args } ) {
        if ( ref $a ) {
            given ($a) {
                when ( $a->isa('TPath::Attribute') ) {
                    $a = $a->apply( $n, $c, $i )
                }
                when ( $a->isa('TPath::AttributeTest') ) {
                    $a = $a->test( $n, $c, $i )
                }
                when ( $a->isa('TPath::Expression') ) {
                    $a = [ $a->select( $n, $i ) ]
                }
                when ( $a->does('TPath::Test') ) { $a = $a->test( $n, $c, $i ) }
                default { confess 'unknown argument type: ' . ( ref $a ) }
            }
        }
        push @args, $a;
    }
    $i->f->$method(@args);
}

__PACKAGE__->meta->make_immutable;

1;
