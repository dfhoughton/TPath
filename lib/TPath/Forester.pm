package TPath::Forester;

# ABSTRACT: a generator of TPath expressions for a particular class of nodes

use Moose;
use namespace::autoclean;

use TPath::Compiler qw(compile);
use TPath::Grammar qw(parse);
use TPath::StderrLog;
use TPath::Attributes::Standard;

with 'TPath::Attributes::Standard';

has log_stream => (
    is      => 'rw',
    isa     => 'TPath::LogStream',
    default => sub { TPath::StderrLog->new }
);

=method path

Takes a TPath expression and returns a L<TPath::Expression>.

=cut

sub path {
    my ( $self, $expr ) = @_;
    my $ast = parse($expr);
    return compile( $ast, $self );
}

=method index

Takes a tree node and returns a L<TPath::Index> object that
L<TPath::Expression> objects can use to cache information about
the tree rooted at the given node.

=cut

sub index {
    my ( $self, $node ) = @_;
}

protected_method kids => sub {

}

protected_method children => sub {

}

protected_method parent => sub {

}

__PACKAGE__->meta->make_immutable;

1;
