# ABSTRACT: a generator of TPath expressions for a particular class of nodes

package TPath::Forester;

use Modern::Perl;
use Moose;
use Carp;

#use namespace::autoclean -also => qr/^_/;

use TPath;
use TPath::Step;

has class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=method path

takes a path expression string returns a L<TPath> object
capable of applying this expression to nodes of the appropriate
class

=cut

sub path {
    my ( $self, $expr ) = @_;
    return TPath->new( class => $self->class, steps => $self->_parse($expr) );
}

our $path_grammar;
{
    use Regexp::Grammars;
    $path_grammar = qr{

<treepath>

   <rule: treepath> <path> ( \| <path> )*

   <token: path> <first_step> <subsequent_step>*+

   <token: first_step> <separator>?+ <step>

   <token: id> id\( (?:[^)\\]|\\.)++ \)

   <token: subsequent_step> <separator> <step>

   <token: separator> \/[\/>]?+

   <token: step> (?: <full> | <abbreviated> ) <predicate>*+

   <token: full> <axis>?+ <forward>

   <token: axis> (?<!/) (?<!/>) <axis_name> ::

   <token: axis_name>
      (?>s(?>ibling(?>-or-self)?+|elf)|p(?>receding(?>-sibling)?+|arent)|leaf|following(?>-sibling)?+|descendant(?>-or-self)?+|child|ancestor(?>-or-self)?+)

   <token: abbreviated> (?<!//) (?<!/>) ( \.{1,2} | <id> )

   <token: forward> <wildcard> | <specific> | <pattern>

   <token: wildcard> \*

   <token: specific> (?:\\.|[\p{L}$ _])(?:[\p{L}$ \p{N}_]|[-:](?=[\p{L}_$ \p{N}])|\\.)*+

   <token: pattern> ~(?:[^~]|~~)++~

   <token: aname> \@ (?:[\p{L}_$ ]|\\.)(?:[\p{L}_$ \p{N}]|[-:](?=[\p{L}_\p{N}])|\\.)*+

   <rule: attribute> <aname> <args>?

   <rule: args> \( <arg> ( ,  <arg> )* \)

   <token: arg> <treepath> | <literal> | <num> | <attribute> | <attribute_test> | <condition>

   <token: num> <.signed_int> | <.float>

   <token: signed_int> [+-]?+ <.int>)   

   <token: float> [+-]?+ <.int>?+ \.\d++ (?: [Ee][+-]?+ <.int> )?+

   <token: literal>
      ( <.squote> | <.dquote> )
      (?{ $MATCH =~ s/^.(.*).$/$1/; $MATCH =~ s/\\(.)/$1/g })

   <token: squote> '(?:[^']|\\.)*+'   

   <token: dquote> "(?:[^\"]|\\.)*+"   

   <rule: predicate>
      \[ (?: <signed_int> | <treepath> | <attribute_test> | <condition> ) \]

   <token: int> \b(?:0|[1-9][0-9]*+)\b

   <token: condition> 
      <term> | <not_cnd> | <or_cnd> | <and_cnd> | <xor_cnd> | <group>

   <token: term> 
      <attribute> | <attribute_test> | <treepath>

   <rule: attribute_test>
      <attribute> <cmp> <value> | <value> <cmp> <attribute>

   <token: cmp> [<>=]=?|!=

   <token: value> <literal> | <num> | <attribute>

   <rule: group> \( <condition> \)

   <rule: not_cnd>
      !|(?<!\/)\bnot\b(?!\/) <[condition]>
      <require: _not_precedence($MATCH{condition})>

   <rule: or_cnd>
      <[condition]> (?: \|{2}|(?<!/)\bor\b(?!/) <[condition]> )+

   <rule: and_cnd>
      <[condition]> (?: &|(?<!/)\band\b(?!/) <[condition]> )+
      <require: _and_precedence($MATCH{condition})>

   <rule: xor_cnd>
      <[condition]> (?: ^|(?<!/)\bxor\b(?!/) <[condition]> )+
      <require: _xor_precedence($MATCH{condition})>
}x;
}

# USED DURING PARSING

# converts an expression to a sequence of TPath::Steps.
#
sub _parse {
    my ( $self, $expr ) = @_;
    if ( $expr =~ $path_grammar ) {
        return \%/;
    }
    else {
        confess "could not parse '$expr' as a TPath expression";
    }
}

our $not_precedence = { map { $_ => 1 } qw(not_cnd term group) };
our $and_precedence = { map { $_ => 1 } qw(and_cnd not_cnd term group) };
our $xor_precedence =
  { map { $_ => 1 } qw(xor_cnd and_cnd not_cnd term group) };

# true if the children of the relevant logical operator are not
# licensed by its precedence
sub _precedence_test {
    my ( $h, $a ) = @_;
    for my $c (@$a) {
        my ($rule) = each %$c;
        return 1 unless $h->{$rule};
    }
    return 0;
}

sub _not_precedence {
    _precedence_test( $not_precedence, @_ );
}

sub _and_precedence {
    _precedence_test( $and_precedence, @_ );
}

sub _xor_precedence {
    _precedence_test( $xor_precedence, @_ );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
