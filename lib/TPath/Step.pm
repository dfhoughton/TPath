# ABSTRACT: a segment of a TPath expression

package TPath::Step;

use Modern::Perl;
use Moose;
use Carp;
use namespace::autoclean -also => qr/^_/;

__PACKAGE__->meta->make_immutable;

1;

__END__
