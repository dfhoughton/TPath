# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(parse %AXES);

use Carp;

our %AXES = map { $_ => 1 } qw(
    ancestor
    ancestor-or-self
    child
    descendant
    descendant-or-self
    following
    following-sibling
    leaf
    parent
    preceding
    preceding-sibling
    self
    sibling
    sibling-or-self
);

our $path_grammar = do {
    use Regexp::Grammars;
    qr{
    <logfile: /tmp/rx.log>
    <nocontext:>
    <timeout: 1>
    
    ^ <treepath> $
    
       <rule: treepath> <[path]> (?> \| <[path]> )*
    
       <token: path> <[segment=first_step]> <[segment=subsequent_step]>*
    
       <token: first_step> <separator>? <step>
    
       <token: id> id\( ( (?>[^\)\\]|\\.)++ ) \) (?{ $MATCH=$^N })
    
       <token: subsequent_step> <separator> <step>
    
       <token: separator> \/[\/>]?+
    
       <token: step> (?: <full> | <abbreviated> ) <[predicate]>*
    
       <token: full> <axis>? <forward>
    
       <token: axis> (?<!/) (?<!/>) <%AXES> ::
    
       <token: abbreviated> (?<!//) (?<!/>) (?> \.{1,2}+ | <id> )
    
       <token: forward> (?> <wildcard> | <specific> | <pattern> )
    
       <token: wildcard> \*
    
       <token: specific> (?>\\.|[\\\p{L}\$_])(?>[\\\p{L}\$\p{N}_]|[-:](?=[\\`\p{L}_\$\p{N}])|\\.)*+
    
       <token: pattern>
          (~(?>[^~]|~~)++~)
          (?{ $MATCH = clean_pattern($^N) })
    
       <token: aname>
          @ ( (?>[\\\p{L}_\$]|\\.)(?>[\p{L}_\$\p{N}]|[-:](?=[\\\p{L}_\p{N}])|\\.)*+ )
          (?{ ( $MATCH = $^N ) =~ s/\\(.)/$1/g })
    
       <rule: attribute> <aname> <args>?
    
       <rule: args> \( (*COMMIT) <[arg]> (?> ,  <[arg]> )* \)
    
       <token: arg>
          (?: <treepath> | <literal> | <num> | <attribute> | <attribute_test> | <condition> )
    
       <token: num> <.signed_int> | <.float>
    
       <token: signed_int> [+-]?+ <.int>   
    
       <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+
    
       <token: literal>
          ((?> <.squote> | <.dquote> ))
          (?{ $MATCH = clean_literal($^N) })
    
       <token: squote> ' (*COMMIT) (?>[^'\\]|\\.)*+ '
    
       <token: dquote> " (*COMMIT) (?>[^"\\]|\\.)*+ "   
    
       <rule: predicate>
          \[ (?: <idx=signed_int> | <condition> ) \]
    
       <token: int> \b(?:0|[1-9][0-9]*+)\b
    
       <token: condition> 
          (?: <term> | <group> | <not_cnd> | <or_cnd> | <and_cnd> | <xor_cnd> )
    
       <token: term> 
          (?: <attribute> | <attribute_test> | <treepath> )
    
       <rule: attribute_test>
          <attribute> <cmp> <value> | <value> <cmp> <attribute>
    
       <token: cmp> [<>=]=?+|!=
    
       <token: value> <literal> | <num> | <attribute>
    
       <rule: group> \( <condition> \)
    
       <rule: not_cnd>
          (?: ! | (?<!\/)\bnot\b(?!\/) ) <[condition]>
          <require: (?{ not_precedence($MATCH{condition}) }) >
    
       <rule: or_cnd>
          <[condition]> (?: (?: \|{2} | (?<!/)\bor\b(?!/) ) <[condition]> )+
    
       <rule: and_cnd>
          <[condition]> (?: (?: & | (?<!/)\band\b(?!/) ) <[condition]> )+
          <require: (?{ and_precedence($MATCH{condition}) }) >
    
       <rule: xor_cnd>
          <[condition]> (?: (?: ^ | (?<!/)\bxor\b(?!/) ) <[condition]> )+
          <require: (?{ xor_precedence($MATCH{condition}) }) >
    }x;
};

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

sub clean_literal {
    my $m = shift;
    $m = substr $m, 1, -1;
    $m =~ s/\\(.)/$1/g;
    return $m;
}

sub clean_pattern {
    my $m = shift;
    $m = substr $m, 1, -1;
    $m =~ s/~~/~/g;
	return $m;
}

1;

__END__
