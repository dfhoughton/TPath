package TPath::LogStream;

# ABSTRACT : role of log-like things

=head1 DESCRIPTION

Behavior required by object to which L<TPath::Forester> delegates logging.

=cut

use Moose::Role;

=method put

Prints a message to the log.

=cut

requires 'put';

1;
