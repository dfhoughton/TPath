package TPath::StderrLog;

# ABSTRACT : implementation of TPath::LogStream that simply prints to STDERR

=head1 DESCRIPTION

Default L<TPath::LogStream>.

=cut

use Moose;
use namespace::autoclean;

with 'TPath::LogStream';

sub put {
    my ( $self, $message ) = @_;
    print STDERR $message, "\n";
}

__PACKAGE__->meta->make_immutable;

1;
