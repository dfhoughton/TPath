package TPath::Stringifiable;

# ABSTRACT: role requiring that a class have a to_string method

=head1 DESCRIPTION

Role that enforces the presence of a to_string method. Makes sure the absence of this method
where it is expected will be a compile time rather than run time error.

=cut

use Moose::Role;
use Scalar::Util qw(looks_like_number);

=head1 REQUIRED METHODS

=head2 to_string

Produces a sensible, human-readable stringification of the object. Some implementations of the method
may expect parameters.

=cut

requires 'to_string';

# method available to to_string that adds escape characters as needed
# params: string -- string to escape
#         chars  -- characters to escape -- \ always added
sub _escape {
    my ( $self, $string, @chars ) = @_;
    my $s = '';
    my %chars = map { $_ => 1 } @chars, '\\';
    for my $c ( split //, $string ) {
        $s .= '\\' if $chars{$c};
        $s .= $c;
    }
    return $s;
}

# general stringification procedure
sub _stringify {
    my ( $self, $arg, @args ) = @_;
    return $arg->to_string(@args)
      if blessed $arg && $arg->can('to_string');
    confess 'unexpected argument type: ' . ref $arg if ref $arg;
    return $arg if looks_like_number $arg;
    return "'" . $self->_escape( $arg, "'" ) . "'";
}

# converts some label -- tag name or attribute name -- into a parsable string
sub _stringify_label {
    my ( $self, $string, $first ) = @_;
    return $string
      if $string =~
      /^(?>\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-.:](?=[\p{L}_\$\p{N}])|\\.)*+$/;
    return ( $first ? ':' : '' ) . '"' . $self->_escape($string) . '"'
      unless ( index $string, '"' ) > -1;
    return ( $first ? ':' : '' ) . "'" . $self->_escape($string) . "'"
      unless ( index $string, "'" ) > -1;

    # safety fallback
    return $self->_escape( $string, grep { !/[\p{L}]\$_/ } split //, $string );
}

1;
