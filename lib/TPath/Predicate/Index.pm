package TPath::Predicate::Index;

# ABSTRACT: implements the C<[0]> in C<//a/b[0]>

=head1 DESCRIPTION

The object that selects the correct member of collection based on its index.

=cut

use Moose;
use Scalar::Util qw(refaddr);

=head1 ROLES

L<TPath::Predicate>

=cut

with 'TPath::Predicate';

=attr idx

The index of the item selected.

=cut

has idx => ( is => 'ro', isa => 'Int', required => 1 );

has outer => ( is => 'ro', isa => 'Bool', default => 0 );

has algorithm => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $i    = $self->idx;
        return sub {
            return shift->[$i] // ();
          }
          if $self->outer;
        return sub {
            my $c = shift;
            my ( $index, %tally, @ret );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                next if $tally{$p};
                $tally{$p} = 1;
                push @ret, $ctx;
            }
            return @ret;
          }
          if $i == 0;
        return sub {
            my $c = shift;
            my ( $index, %tally, @parents );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                my $ar;
                unless ($ar = $tally{$p}) {
                    push @parents, $p;
                    $ar = $tally{$p} = [];
                }
                push @$ar, $ctx;
            }
            my @ret;
            for my $p (@parents) {
                my $ctx = $tally{$p}[$i];
                push @ret, $ctx if $ctx;
            }
            return @ret;
          }
          if $i < 0;
        return sub {
            my $c = shift;
            my ( $index, %tally, @ret );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                $tally{$p} //= 0;
                push @ret, $ctx if $tally{$p}++ == $i;
            }
            return @ret;
        };
    },
);

sub filter {
    my ( $self, $c ) = @_;
    return $self->algorithm->($c);
}

sub to_string {
    $_[0]->idx;
}

__PACKAGE__->meta->make_immutable;

1;
