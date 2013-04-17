# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;

use v5.10;
use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(parse %AXES);

=head1 SYNOPSIS

    use TPath::Grammar qw(parse);

    my $ast = parse('/>a[child::b || @foo("bar")][-1]');

=head1 DESCRIPTION

C<TPath::Grammar> exposes a single function: C<parse>. Parsing is a preliminary step to
compiling the expression into an object that will select the tree nodes matching
the expression.

C<TPath::Grammar> is really intended for use by C<TPath> modules, but if you want 
a parse tree, here's how to get it.

Also exportable from C<TPath::Grammar> is C<%AXES>, the set of axes understood by TPath
expressions. See L<TPath> for the list and explanation.

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
  previous
  self
  sibling
  sibling-or-self
);

our $offset       = 0;
our $path_grammar = do {
    our $buffer;
    use Regexp::Grammars;
    qr{
       <nocontext:>
       <timeout: 10>
    
    \A <.ws> <treepath> <.ws> \Z
    
       <rule: treepath> <[path]> (?: \| <[path]> )*
    
       <token: path> (?![\@'"]) <[segment]> (?: (?= / | \( <.ws> / ) <[segment]> )*
    
       <token: segment> (?: <separator>? <step> | <cs> ) <.ws>
       
       <token: quantifier> (?: [?+*] | <enum> ) <.cp>
       
       <rule: enum> [{] <start=(\d*+)> (?: , <end=(\d*+)> )? [}]
       
       <rule: grouped_step> \( <treepath> \) <quantifier>?
    
       <token: id>
          :id\( ( (?>[^\)\\]|\\.)++ ) \)
          (?{ $MATCH=clean_escapes($^N) }) <.cp>
    
       <token: cs>
           <separator>? <step> <quantifier>
          | <grouped_step>
    
       <token: separator> \/[\/>]?+ <.cp>
    
       <token: step> <full> (?: <.ws> <[predicate]> )* | <abbreviated>
    
       <token: full> <axis>? <forward> | (?<=(?<!/)/) <previous=(:p)> <.cp>
    
       <token: axis> 
          (?<!//) (?<!/>) (<%AXES>) ::
          (?{ $MATCH = $^N }) <.cp>
    
       <token: abbreviated> (?<!/[/>]) (?: \.{1,2}+ | <id> | :root ) <.cp>
    
       <token: forward> 
           <wildcard> | <complement=(\^)>? (?: <specific> | <pattern> | <attribute> )
    
       <token: wildcard> \* <.start_of_path> <.cp>
       
       <token: start_of_path> # somewhat lame way to make sure * quantifier isn't misinterpreted as the wildcard character
          (?<=[/:>].)
          | (?<=\(.)
          | (?<=\(\s.)
          | (?<=\(\s{2}.)
          | (?<=\(\s{3}.)
          | (?<=\(\s{4}.) # if the user puts more than 4 whitespace characters between ) and *, it will be mis-parsed
          | (?<=\A.)
          | (?<=\A\s.)
          | (?<=\A\s{2}.)
          | (?<=\A\s{3}.)
          | (?<=\A\s{4}.)
    
       <token: specific>
          <name>
          (?{ $MATCH = $MATCH{name} }) <.cp>
    
       <token: pattern>
          (~(?>[^~]|~~)++~)
          (?{ $MATCH = clean_pattern($^N) }) <.cp>
    
       <token: aname>
          @ <name>
          (?{ $MATCH = $MATCH{name} })
       
       <token: name>
          ((?>\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-.:](?=[\p{L}_\$\p{N}])|\\.)*+)  (?{ $MATCH = clean_escapes($^N ) })
          | <literal> (?{ $MATCH = $MATCH{literal} })
          | (<.qname>) (?{ $MATCH = clean_escapes( substr $^N, 2, length($^N) -3 ) })
       
       <token: qname> 
          : ([[:punct:]].+?[[:punct:]]) 
          <require: (?{qname_test($^N)})> <.cp> 
     
       <rule: attribute> <aname> <args>?
    
       <rule: args> \( <[arg]> (?: , <[arg]> )* \) <.cp>
    
       <token: arg>
           <v=literal> | <v=num> | <attribute> | <treepath> | <attribute_test> | <condition>
    
       <token: num> <.signed_int> | <.float>
    
       <token: signed_int> [+-]?+ <.int> <.cp>
    
       <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+ <.cp>
    
       <token: literal>
          ((?> <.squote> | <.dquote> ))
          (?{ $MATCH = clean_literal($^N) })
    
       <token: squote> ' (?>[^'\\]|\\.)*+ ' <.cp>
    
       <token: dquote> " (?>[^"\\]|\\.)*+ " <.cp>
    
       <rule: predicate>
          \[ (*COMMIT) (?: <idx=signed_int> | <condition> ) \] <.cp>
    
       <token: int> \b(?:0|[1-9][0-9]*+)\b <.cp>
    
       <rule: condition> 
          <[item=not]>? <[item]> (?: <[item=operator]> <[item=not]>? <[item]> )*

       <token: not>
          ( 
             (?: ! | (?<=[\s\[(]) not (?=\s) ) 
             (?: \s*+ (?: ! | (?<=\s) not (?=\s) ) )*+ 
          )
          (?{$MATCH = clean_not($^N)}) <.cp>
       
       <token: operator>
          (?: <.or> | <.xor> | <.and> )
          (?{$MATCH = clean_operator($^N)})
       
       <token: xor> (?: ; | (?<=\s) one (?=\s) ) <.cp>
           
       <token: and> (?: & | (?<=\s) and (?=\s) ) <.cp>
           
       <token: or> (?: \|{2} | (?<=\s) or (?=\s) ) <.cp>
    
       <token: term> <attribute> | <attribute_test> | <treepath>
    
       <rule: attribute_test>
          <[args=attribute]> <cmp> <[args=value]> | <[args=value]> <cmp> <[args=attribute]>
    
       <token: cmp> (?: [<>=]=?+ | ![=~] | =~ | =?\|= | =\| ) <.cp>
    
       <token: value> <v=literal> | <v=num> | <attribute>
    
       <rule: group> \( <condition> \) <.cp>
    
       <token: item> <term> | <group>
          
       <token: ws> (?: \s*+ (?: \#.*? $ )?+ )*+ <.cp>
       
       <token: cp> # "checkpoint"
          (?{ $offset = $INDEX if $INDEX > $offset })
    }xms;
};

=func parse

Converts a TPath expression to a parse tree, normalizing boolean expressions
and parentheses and unescaping escaped strings. C<parse> throws an error with
a stack trace if the expression is unparsable. Otherwise it returns a hashref.

=cut

sub parse {
    local $offset = 0;
    my ($expr) = @_;
    if ( $expr =~ $path_grammar ) {
        my $ref = \%/;
        normalize_compounds($ref);
        complement_to_boolean($ref);
        if ( contains_condition($ref) ) {
            normalize_parens($ref);
            operator_precedence($ref);
            merge_conditions($ref);
            fix_predicates($ref);
        }
        optimize($ref);
        return $ref;
    }
    else {
        die "could not parse '$expr' as a TPath expression; "
          . error_message( $expr, $offset );
    }
}

# constructs an error message indicating the parsable portion of the expression
sub error_message {
    my ( $expr, $offset ) = @_;
    my $start = $offset - 20;
    $start = 0 if $start < 0;
    my $prefix = substr $expr, 0, $offset;
    my $end = $offset + 20;
    $end = length $expr if length $expr < $end;
    my $suffix = substr $expr, $offset, $end - $offset;
    my $error = 'matching failed at position marked by <HERE>: ';
    $error .= '...'   if $start > 0;
    $error .= $prefix if $prefix;
    $error .= '<HERE>';
    $error .= $suffix if $suffix;
    $error .= '...'   if $end < length $expr;
    return $error;
}

# convert (/foo) to /foo and (/foo)? to /foo?
sub normalize_compounds {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {

            # depth first
            normalize_compounds($_) for values %$ref;

            my $cs = $ref->{cs};
            if ($cs) {
                normalize_enums($cs);
                my $gs = $cs->{grouped_step};
                if (   $gs
                    && @{ $gs->{treepath}{path} } == 1
                    && @{ $gs->{treepath}{path}[0]{segment} } == 1 )
                {
                    my $quantifier = $gs->{quantifier};
                    my $step       = $gs->{treepath}{path}[0]{segment}[0];
                    $step->{quantifier} = $quantifier if $quantifier;
                    $ref->{cs} = $step;
                }
            }
        }
        when ('ARRAY') {

            # depth first
            normalize_compounds($_) for @$ref;

            my $among_steps;
            for my $i ( 0 .. $#$ref ) {
                my $v = $ref->[$i];
                last unless $among_steps // ref $v;
                my $cs = $v->{cs};
                $among_steps //= $cs // 0 || $v->{step} // 0;
                last unless $among_steps;
                if ($cs) {
                    if ( $cs->{step} ) {
                        if ( !$cs->{quantifier} ) {
                            splice @$ref, $i, 1, $cs;
                        }
                        elsif ( $cs->{quantifier} eq 'vacuous' ) {
                            delete $cs->{quantifier};
                            splice @$ref, $i, 1, $cs;
                        }
                    }
                    elsif (
                        ( $cs->{grouped_step}{quantifier} // '' ) eq 'vacuous' )
                    {
                        my $path = $cs->{grouped_step}{treepath}{path};
                        if ( @$path == 1 ) {
                            splice @$ref, $i, 1, @{ $path->[0]{segment} };
                        }
                    }
                }
            }
        }
    }
}

# normalizes enumerated quantifiers
sub normalize_enums {
    my $cs         = shift;
    my $is_grouped = exists $cs->{grouped_step};
    my $q =
        $is_grouped
      ? $cs->{grouped_step}{quantifier}
      : $cs->{quantifier};
    return unless $q && ref $q;
    my $enum          = $q->{enum};
    my $start_defined = $enum->{start} ne '';
    my $start         = $enum->{start} ||= 0;
    my $end;

    if ( exists $enum->{end} ) {
        $end = $enum->{end} || 0;
    }
    else {
        $end = $start;
    }
    if ( $end == 1 ) {
        if ( $start == 1 ) {
            if ($is_grouped) {
                $cs->{grouped_step}{quantifier} = 'vacuous';
            }
            else {
                $cs->{quantifier} = 'vacuous';
            }
            return;
        }
        if ( $start == 0 ) {
            if ($is_grouped) {
                $cs->{grouped_step}{quantifier} = '?';
            }
            else {
                $cs->{quantifier} = '?';
            }
            return;
        }
    }
    elsif ( $start == 1 && $end == 0 ) {
        if ($is_grouped) {
            $cs->{grouped_step}{quantifier} = '+';
        }
        else {
            $cs->{quantifier} = '+';
        }
        return;
    }
    elsif ( $start_defined && $start == 0 && ( $enum->{end} // 'bad' ) eq '' ) {
        if ($is_grouped) {
            $cs->{grouped_step}{quantifier} = '*';
        }
        else {
            $cs->{quantifier} = '*';
        }
        return;
    }
    die 'empty {x,y} quantifier' unless $start || $end;
    die 'in {x,y} quantifier end is less than start'
      if $start > $end && ( $enum->{end} // '' ) ne '';
    $enum->{end} = $end;
}

# converts complement => '^' to complement => 1 simply to make AST function clearer
sub complement_to_boolean {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            for my $k ( keys %$ref ) {
                if ( $k eq 'complement' ) { $ref->{$k} &&= 1 }
                else { complement_to_boolean( $ref->{$k} ) }
            }
        }
        when ('ARRAY') { complement_to_boolean($_) for @$ref }
    }
}

# remove no-op steps etc.
sub optimize {
    my $ref = shift;
    clean_no_op($ref);
}

# remove . and /. steps
sub clean_no_op {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            my $paths = $ref->{path};
            for my $path ( @{ $paths // [] } ) {
                my @segments = @{ $path->{segment} };
                my @cleaned;
                for my $i ( 1 .. $#segments ) {
                    my $step = $segments[$i];
                    push @cleaned, $step unless find_dot($step);
                }
                if (@cleaned) {
                    my $step = $segments[0];
                    if ( find_dot($step) ) {
                        my $sep  = $step->{separator};
                        my $next = $cleaned[0];
                        my $nsep = $next->{separator};
                        if ($sep) {
                            unshift @cleaned, $step
                              unless $nsep eq '/' && find_axis($next);
                        }
                        else {
                            if ( $nsep eq '/' ) {
                                delete $next->{separator};
                            }
                            else {
                                unshift @cleaned, $step;
                            }
                        }
                    }
                    else {
                        unshift @cleaned, $step;
                    }
                }
                else {
                    @cleaned = @segments;
                }
                $path->{segment} = \@cleaned;
            }
            clean_no_op($_) for values %$ref;
        }
        when ('ARRAY') {
            clean_no_op($_) for @$ref;
        }
    }
}

# returns the axis if any; prevents reification of hash keys
sub find_axis {
    my $next = shift;
    my $step = $next->{step};
    return unless $step;
    my $full = $step->{step};
    return unless $full;
    return $full->{axis};
}

# finds dot, if any; prevents reification of hash keys
sub find_dot {
    my $step = shift;
    exists $step->{step}
      && ( $step->{step}{abbreviated} // '' ) eq '.';
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
    for ($type) {
        when ('HASH') {
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
        when ('ARRAY') { merge_conditions($_) for @$ref }
        default { die "unexpected type $type" }
    }
}

# group operators and arguments according to operator precedence ! > & > ; > ||
sub operator_precedence {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    for ($type) {
        when ('HASH') {
            while ( my ( $k, $v ) = each %$ref ) {
                if ( $k eq 'condition' && ref $v eq 'ARRAY' ) {
                    my @ar = @$v;

                    # normalize ! strings
                    @ar = grep { $_ } map {
                        if ( !ref $_ && /^!++$/ ) {
                            ( my $s = $_ ) =~ s/..//g;
                            $s;
                        }
                        else { $_ }
                    } @ar;
                    $ref->{$k} = \@ar if @$v != @ar;

                    # depth first
                    operator_precedence($_) for @ar;
                    return $ref if @ar == 1;

                    # build binary logical operation tree
                  OUTER: while ( @ar > 1 ) {
                        for my $op (qw(! & ; ||)) {
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
                                                args     => [
                                                    $ar[ $i - 1 ],
                                                    $ar[ $i + 1 ]
                                                ]
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
        when ('ARRAY') { operator_precedence($_) for @$ref }
        default { die "unexpected type $type" }
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
            die "unexpected type: $type";
        }
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
        die 'items in a condition are expected to be either <term> or <group>';
    }
}

# some functions to undo escaping and normalize strings

sub clean_literal {
    my $m = shift;
    $m = substr $m, 1, -1;
    return clean_escapes($m);
}

sub clean_pattern {
    my $m = shift;
    $m = substr $m, 1, -1;
    my $r = '';
    my $i = 0;
    {
        my $j = index $m, '~~', $i;
        if ( $j > -1 ) {
            $r .= substr $m, $i, $j - $i + 1;
            $i = $j + 2;
            redo;
        }
        else {
            $r .= substr $m, $i;
        }
    }
    return $r;
}

sub clean_not {
    my $m = shift;
    return '!' if $m eq 'not';
    return $m;
}

sub clean_operator {
    my $m = shift;
    for ($m) {
        when ('and') { return '&' }
        when ('or')  { return '||' }
        when ('one') { return ';' }
    }
    return $m;
}

sub clean_escapes {
    my $m = shift;
    return '' unless $m;
    my $r = '';
    {
        my $i = index $m, '\\';
        if ( $i > -1 ) {
            my $prefix = substr $m, 0, $i;
            $prefix .= substr $m, $i + 1, 1;
            $m = substr $m, $i + 2;
            $r .= $prefix;
            redo;
        }
        else {
            $r .= $m;
        }
    }
    return $r;
}

sub qname_test {
    my $name = shift;
    my $s    = substr $name, 0, 1;
    my $end  = length($name) - 1;
    my $e    = substr $name, $end, 1;
    my $good;
    for ($s) {
        when ('(') { $good = $e eq ')' }
        when ('{') { $good = $e eq '}' }
        when ('[') { $good = $e eq ']' }
        when ('<') { $good = $e eq '>' }
        default    { $good = $e eq $s }
    }
    if ($good) {
        my $escaped;
        for my $i ( 1 .. $end - 1 ) {
            if ($escaped) {
                $escaped = 0;
                next;
            }
            $s = substr $name, $i, 1;
            if ( $s eq '\\' ) {
                $escaped = 1;
                next;
            }
            return if $s eq $e;
        }
        return $escaped ? 0 : 1;
    }
    return;
}

1;

__END__
