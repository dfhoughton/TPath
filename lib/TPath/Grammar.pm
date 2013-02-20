# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;

use feature 'switch';
use strict;
use warnings;
use Carp;

use parent qw(Exporter);

our @EXPORT_OK = qw(parse %AXES);

=head1 SYNOPSIS

    use TPath::Grammar qw(parse);

    my $ast = parse('/>a[child::b || @foo("bar")][-1]');

=head1 DESCRIPTION

c<TPath::Grammar> exposes a single function: C<parse>. Parsing is a preliminary step to
compiling the expression into an object that will select the tree nodes matching
the expression.

C<TPath::Grammar> is really intended for use by C<TPath> modules, but if you want 
a parse tree, here's how to get it.

=cut

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
    <nocontext:>
    <timeout: 1>
    
    ^ <treepath> $
    
       <rule: treepath> <[path]> (?: \| <[path]> )*
    
       <token: path> <[segment=first_step]> <[segment=subsequent_step]>*
    
       <token: first_step> <separator>? <step>
    
       <token: id>
          id\( ( (?>[^\)\\]|\\.)++ ) \)
          (?{ $MATCH=clean_escapes($^N) })
    
       <token: subsequent_step> <separator> <step>
    
       <token: separator> \/[\/>]?+ (*COMMIT)
    
       <token: step> <full> <[predicate]>* | <abbreviated>
    
       <token: full> <axis>? <forward>
    
       <token: axis> (?<!//) (?<!/>) (<%AXES>) :: (*COMMIT)
          (?{ $MATCH = $^N })
    
       <token: abbreviated> (?<!//) (?<!/>) (?: \.{1,2}+ | <id> )
    
       <token: forward> <wildcard> | <specific> | <pattern>
    
       <token: wildcard> \*
    
       <token: specific>
          ((?>\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-:](?=[\p{L}_\$\p{N}])|\\.)*+)
          (?{ $MATCH = clean_escapes($^N) })
    
       <token: pattern>
          (~(?>[^~]|~~)++~)
          (?{ $MATCH = clean_pattern($^N) })
    
       <token: aname>
          @ ( (?>[\p{L}_\$]|\\.)(?>[\p{L}_\$\p{N}]|[-:](?=[\p{L}_\p{N}])|\\.)*+ )
          (?{ $MATCH = clean_escapes($^N ) })
    
       <rule: attribute> <aname> <args>?
    
       <rule: args> \( <[arg]> (?: , <[arg]> )* \)
    
       <token: arg>
          <treepath> | <v=literal> | <v=num> | <attribute> | <attribute_test> | <condition>
    
       <token: num> <.signed_int> | <.float>
    
       <token: signed_int> [+-]?+ <.int>   
    
       <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+
    
       <token: literal>
          ((?> <.squote> | <.dquote> ))
          (?{ $MATCH = clean_literal($^N) })
    
       <token: squote> ' (*COMMIT) (?>[^'\\]|\\.)*+ '
    
       <token: dquote> " (*COMMIT) (?>[^"\\]|\\.)*+ "   
    
       <rule: predicate>
          \[ (*COMMIT) (?: <idx=signed_int> | <condition> ) \]
    
       <token: int> \b(?:0|[1-9][0-9]*+)\b
    
       <rule: condition> 
          <[item=not]>? <[item]> (?: <[item=operator]> <[item=not]>? <[item]> )*

       <token: not>
          ((?>!|(?<=[\s\[])not(?=\s))(?>\s*+(?>!|(?<=\s)not(?=\s)))*+)
          (?{$MATCH = clean_not($^N)})
       
       <token: operator>
          (?: <.or> | <.xor> | <.and> )
          (?{$MATCH = clean_operator($^N)})
       
       <token: xor>
          ( \^ | (?<=\s) xor (?=\s) )
           
       <token: and>
          ( & | (?<=\s) and (?=\s) )
           
       <token: or>
          ( \|{2} | (?<=\s) or (?=\s) )
    
       <token: term> 
          <attribute> | <attribute_test> | <treepath>
    
       <rule: attribute_test>
          <[args=attribute]> <cmp> <[args=value]> | <[args=value]> <cmp> <[args=attribute]>
    
       <token: cmp> [<>=]=?+|!=
    
       <token: value> <v=literal> | <v=num> | <attribute>
    
       <rule: group> \( (*COMMIT) <condition> \)
    
       <token: item>
          <term> | <group>
    }x;
};

=func parse

Converts a TPath expression to a parse tree, normalizing boolean expressions
and parentheses and unescaping escaped strings. C<parse> throws an error with
a stack trace if the expression is unparsable. Otherwise it returns a hashref.

=cut

sub parse {
    my ($expr) = @_;
    if ( $expr =~ $path_grammar ) {
        my $ref = \%/;
        if ( contains_condition($ref) ) {
            normalize_parens($ref);
            operator_precedence($ref);
            merge_conditions($ref);
            fix_predicates($ref);
        }
        return $ref;
    }
    else {
        confess "could not parse '$expr' as a TPath expression";
    }
}

# remove unnecessary levels in predicate trees
sub fix_predicates {
    my $ref  = shift;
    my $type = ref $ref;
    for ($type) {
        when ('HASH') {
            while ( my ( $k, $v ) = each %$ref ) {
                if ( $k eq 'predicate' ) {
                    for my $i ( 0 .. $#$v ) {
                        my $item = $v->[$i];
                        next if exists $item->{idx};
                        if ( ref $item->{condition} eq 'ARRAY' ) {
                            $item = $item->{condition}[0];
                            splice @$v, $i, 1, $item;
                        }
                        fix_predicates($item);
                    }
                }
                else {
                    fix_predicates($v);
                }
            }
        }
        when ('ARRAY') { fix_predicates($_) for @$ref }
    }
}

# merge nested conditions with the same operator into containing conditions
sub merge_conditions {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            if ( $k eq 'condition' ) {
                if ( !exists $v->{args} ) {
                    merge_conditions($_) for values %$v;
                    next;
                }

                # depth first
                merge_conditions($_) for @{ $v->{args} };
                my $op = $v->{operator};
                my @args;
                for my $a ( @{ $v->{args} } ) {
                    my $condition = $a->{condition};
                    if ( defined $condition ) {
                        my $o = $condition->{operator};
                        if ( defined $o ) {
                            if ( $o eq $op ) {
                                push @args, @{ $condition->{args} };
                            }
                            else {
                                push @args, $a;
                            }
                        }
                        else {
                            push @args, $condition;
                        }
                    }
                    else {
                        push @args, $a;
                    }
                }
                $v->{args} = \@args;
            }
            else {
                merge_conditions($v);
            }
        }
    }
    elsif ( $type eq 'ARRAY' ) {
        merge_conditions($_) for @$ref;
    }
    else {
        confess "unexpected type $type";
    }
    return $ref;
}

# group operators and arguments according to operator precedence ! > & > ^ > ||
sub operator_precedence {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            if ( $k eq 'condition' && ref $v eq 'ARRAY' ) {
                my @ar = @$v;

                # normalize ! strings
                @ar = grep { $_ } map {
                    if ( !ref $_ && /^!++$/ ) { ( my $s = $_ ) =~ s/..//g; $s }
                    else                      { $_ }
                } @ar;
                $ref->{$k} = \@ar if @$v != @ar;

                # depth first
                operator_precedence($_) for @ar;
                return $ref if @ar == 1;

                # build binary logical operation tree
              OUTER: while ( @ar > 1 ) {
                    for my $op (qw(! & ^ ||)) {
                        for my $i ( 0 .. $#ar ) {
                            my $item = $ar[$i];
                            next if ref $item;
                            if ( $item eq $op ) {
                                if ( $op eq '!' ) {
                                    splice @ar, $i, 2,
                                      {
                                        condition => {
                                            operator => '!',
                                            args     => [ $ar[ $i + 1 ] ]
                                        }
                                      };
                                }
                                else {
                                    splice @ar, $i - 1, 3,
                                      {
                                        condition => {
                                            operator => $op,
                                            args =>
                                              [ $ar[ $i - 1 ], $ar[ $i + 1 ] ]
                                        }
                                      };
                                }
                                next OUTER;
                            }
                        }
                    }
                }

                # replace condition with logical operation tree
                $ref->{condition} = $ar[0]{condition};
            }
            else {
                operator_precedence($v);
            }
        }
    }
    elsif ( $type eq 'ARRAY' ) {
        operator_precedence($_) for @$ref;
    }
    else {
        confess "unexpected type $type";
    }
    return $ref;
}

# looks for structures requiring normalization
sub contains_condition {
    my $ref  = shift;
    my $type = ref $ref;
    return 0 unless $type;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            return 1 if $k eq 'condition' || contains_condition($v);
        }
        return 0;
    }
    for my $v (@$ref) {
        return 1 if contains_condition($v);
    }
    return 0;
}

# removes redundant parentheses and simplifies condition elements somewhat
sub normalize_parens {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    for ($type) {
        when ('ARRAY') {
        normalize_parens($_) for @$ref;
        }
        when ('HASH') {
        for my $name ( keys %$ref ) {
            my $value = $ref->{$name};
            if ( $name eq 'condition' ) {
                my @ar = @{ $value->{item} };
                for my $i ( 0 .. $#ar ) {
                    $ar[$i] = normalize_item( $ar[$i] );
                }
                $ref->{condition} = \@ar;
            }
            else {
                normalize_parens($value);
            }
        }
        }
        default {
        confess "unexpected type: $type";
        }
    }
    if ( $type eq 'ARRAY' ) {
    }
    elsif ( $type eq 'HASH' ) {
    }
    else {
    }
    return $ref;
}

# normalizes parentheses in a condition item
sub normalize_item {
    my $item = shift;
    return $item unless ref $item;
    if ( exists $item->{term} ) {
        return normalize_parens( $item->{term} );
    }
    elsif ( exists $item->{group} ) {

        # remove redundant parentheses
        while ( exists $item->{group}
            && @{ $item->{group}{condition}{item} } == 1 )
        {
            $item = $item->{group}{condition}{item}[0];
        }
        return normalize_parens( $item->{group} // $item->{term} );
    }
    else {
        confess
          'items in a condition are expected to be either <term> or <group>';
    }
}

# some functions to undo escaping and normalize strings

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

sub clean_not {
    my $m = shift;
    $m =~ s/not/!/g;
    $m =~ s/\s++//g;
    return $m;
}

sub clean_operator {
    my $m = shift;
    $m =~ s/and/&/;
    $m =~ s/xor/^/;
    $m =~ s/or/||/;
    return $m;
}

sub clean_escapes {
    my $m = shift // '';
    $m =~ s/\\(.)/$1/g;
    return $m;
}

1;

__END__
