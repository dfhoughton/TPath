# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT = qw(parse);

use Carp;
use Regexp::Grammars;

our $path_grammar = qr{

^ <treepath> $

<nocontext:>

   <rule: treepath> <[path]> (?: \| <[path]> )*

   <token: path> <[segment=first_step]> <[segment=subsequent_step]>*

   <token: first_step> <separator>? <step>

   <token: id> id\( ( (?:[^\)\\]|\\.)++ ) \) (?{ $MATCH=$^N })

   <token: subsequent_step> <separator> <step>

   <token: separator> \/[\/>]?

   <token: step> (?: <full> | <abbreviated> ) <[predicate]>*

   <token: full> <axis>? <forward>

   <token: axis> (?<!/) (?<!/>) <axis_name> ::

   <token: axis_name>
      (?>s(?>ibling(?>-or-self)?+|elf)|p(?>receding(?>-sibling)?+|arent)|leaf|following(?>-sibling)?+|descendant(?>-or-self)?+|child|ancestor(?>-or-self)?+)

   <token: abbreviated> (?<!//) (?<!/>) (?: \.{1,2} | <id> )

   <token: forward> <wildcard> | <specific> | <pattern>

   <token: wildcard> \*

   <token: specific> (?:\\.|[\p{L}\$_])(?:[\p{L}\$\p{N}_]|[-:](?=[\p{L}_\$\p{N}])|\\.)*+

   <token: pattern> ~(?:[^~]|~~)++~

   <token: aname>
      @ ( (?:[\p{L}_$ ]|\\.)(?:[\p{L}_$ \p{N}]|[-:](?=[\p{L}_\p{N}])|\\.)*+ )
      (?{ $MATCH = $^N; $MATCH =~ s/\\(.)/$1/g })

   <rule: attribute> <aname> <args>?

   <rule: args> \( <[arg]> (?: ,  <[arg]> )* \)

   <token: arg> <treepath> | <literal> | <num> | <attribute> | <attribute_test> | <condition>

   <token: num> <.signed_int> | <.float>

   <token: signed_int> [+-]?+ <.int>   

   <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+

   <token: literal>
      ( <.squote> | <.dquote> )
      (?{ $MATCH =~ s/^.(.*).$/$1/; $MATCH =~ s/\\(.)/$1/g })

   <token: squote> '(?:[^']|\\.)*+'   

   <token: dquote> "(?:[^\"]|\\.)*+"   

   <rule: predicate>
      \[ (?: <idx=signed_int> | <condition> ) \]

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
      <require: (?{ not_precedence($MATCH{condition}) }) >

   <rule: or_cnd>
      <[condition]> (?: \|{2}|(?<!/)\bor\b(?!/) <[condition]> )+

   <rule: and_cnd>
      <[condition]> (?: &|(?<!/)\band\b(?!/) <[condition]> )+
      <require: (?{ and_precedence($MATCH{condition}) }) >

   <rule: xor_cnd>
      <[condition]> (?: ^|(?<!/)\bxor\b(?!/) <[condition]> )+
      <require: (?{ xor_precedence($MATCH{condition}) }) >
}x;

sub parse {
    my ($expr) = @_;
    if ( $expr =~ $path_grammar ) {
        return \%/;
    }
    else {
        confess "could not parse '$expr' as a TPath expression";
    }
}

our $not_precedence = { map { $_ => 1 } qw(not_cnd term group) };
our $and_precedence = { 'and_cnd' => 1, %$not_precedence };
our $xor_precedence = { 'xor_cnd' => 1, %$and_precedence };

# true if the children of the relevant logical operator are not
# licensed by its precedence
sub precedence_test {
    my ( $h, $a ) = @_;
    for my $c (@$a) {
        my ($rule) = each %$c;
        return 0 unless $h->{$rule};
    }
    return 1;
}

sub not_precedence {
    precedence_test( $not_precedence, @_ );
}

sub and_precedence {
    precedence_test( $and_precedence, @_ );
}

sub xor_precedence {
    precedence_test( $xor_precedence, @_ );
}

1;

__END__
