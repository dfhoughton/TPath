# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;

use v5.10;
use strict;
use warnings;
use Carp;

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
    
    ^ <treepath> $
    
       <rule: treepath> <[path]> (?: \| <[path]> )*
    
       <token: path> (?!@) <[segment]>+ (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: segment> (?: <separator>? <step> | <cs> ) (?{ $offset = $INDEX if $INDEX > $offset })
       
       <token: quantifier> (?: [?+*] | <enum> ) (?{ $offset = $INDEX if $INDEX > $offset })
       
       <rule: enum> [{] <start=(\d*+)> (?: , <end=(\d*+)> )? [}]
       
       <token: grouped_step> \( \s*+ <treepath> \s*+ \) <quantifier>? (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: id>
          :id\( ( (?>[^\)\\]|\\.)++ ) \)
          (?{ $MATCH=clean_escapes($^N) })
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: cs>
          (?:
          <separator>? <step> <quantifier>
          | <grouped_step>
          ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: separator> \/[\/>]?+ (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: step> (?: <full> <[predicate]>* | <abbreviated> ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: full> <axis>? <forward> (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: axis> 
          (?<!//) (?<!/>) (<%AXES>) ::
          (?{ $MATCH = $^N })
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: abbreviated> (?<!/[/>]) (?: \.{1,2}+ | <id> | :root ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: forward> 
           (?: <wildcard> | <complement=(\^)>? (?: <specific> | <pattern> | <attribute> ) )
           (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: wildcard> \* <.start_of_path> (?{ $offset = $INDEX if $INDEX > $offset })
       
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
          (?{ $MATCH = $MATCH{name} })
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: pattern>
          (~(?>[^~]|~~)++~)
          (?{ $MATCH = clean_pattern($^N) })
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: aname>
          @ <name>
          (?{ $MATCH = $MATCH{name} })
          (?{ $offset = $INDEX if $INDEX > $offset })
       
       <token: name>
          (?:
          ((?>\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-.:](?=[\p{L}_\$\p{N}])|\\.)*+)  (?{ $MATCH = clean_escapes($^N ) })
          | (<.qname>) (?{ $MATCH = clean_escapes( substr $^N, 2, length($^N) -3 ) })
          ) (?{ $offset = $INDEX if $INDEX > $offset })
       
       <token: qname> 
          : (\p{PosixPunct}.+?\p{PosixPunct}) 
          <require: (?{qname_test($^N)})>
          (?{ $offset = $INDEX if $INDEX > $offset }) 
     
       <rule: attribute> <aname> <args>? (?{ $offset = $INDEX if $INDEX > $offset })
    
       <rule: args> \( <[arg]> (?: , <[arg]> )* \) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: arg>
          (?:
          <treepath> | <v=literal> | <v=num> | <attribute> | <attribute_test> | <condition>
          ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: num> (?: <.signed_int> | <.float> ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: signed_int> [+-]?+ <.int> (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+ (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: literal>
          ((?> <.squote> | <.dquote> ))
          (?{ $MATCH = clean_literal($^N) })
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: squote> ' (?>[^'\\]|\\.)*+ ' (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: dquote> " (?>[^"\\]|\\.)*+ " (?{ $offset = $INDEX if $INDEX > $offset })
    
       <rule: predicate>
          \[ (*COMMIT) (?: <idx=signed_int> | <condition> ) \]
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: int> \b(?:0|[1-9][0-9]*+)\b (?{ $offset = $INDEX if $INDEX > $offset })
    
       <rule: condition> 
          <[item=not]>? <[item]> (?: <[item=operator]> <[item=not]>? <[item]> )*
          (?{ $offset = $INDEX if $INDEX > $offset })

       <token: not>
          ( 
             (?: ! | (?<=[\s\[(]) not (?=\s) ) 
             (?: \s*+ (?: ! | (?<=\s) not (?=\s) ) )*+ 
          )
          (?{$MATCH = clean_not($^N)})
          (?{ $offset = $INDEX if $INDEX > $offset })
       
       <token: operator>
          (?: <.or> | <.xor> | <.and> )
          (?{$MATCH = clean_operator($^N)})
          (?{ $offset = $INDEX if $INDEX > $offset })
       
       <token: xor>
          ( ` | (?<=\s) one (?=\s) ) (?{ $offset = $INDEX if $INDEX > $offset })
           
       <token: and>
          ( & | (?<=\s) and (?=\s) ) (?{ $offset = $INDEX if $INDEX > $offset })
           
       <token: or>
          ( \|{2} | (?<=\s) or (?=\s) ) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: term> 
          (?: <attribute> | <attribute_test> | <treepath> )
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <rule: attribute_test>
          (?: <[args=attribute]> <cmp> <[args=value]> | <[args=value]> <cmp> <[args=attribute]> )
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: cmp> [<>=]=?+|![=~]|=~ (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: value> 
          (?: <v=literal> | <v=num> | <attribute> )
          (?{ $offset = $INDEX if $INDEX > $offset })
    
       <rule: group> \( <condition> \) (?{ $offset = $INDEX if $INDEX > $offset })
    
       <token: item>
          (?: <term> | <group> ) (?{ $offset = $INDEX if $INDEX > $offset })
    }x;
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
		confirm_separators( $ref, 0 );
		return $ref;
	}
	else {
		confess "could not parse '$expr' as a TPath expression; "
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

# require a separator before all non-initial steps
sub confirm_separators {
	my ( $ref, $non_initial ) = @_;
	for ( ref $ref ) {
		when ('ARRAY') { confirm_separators( $_, $non_initial ) for @$ref }
		when ('HASH') {
			my ($path) = $ref->{path};
			if ($path) {
				for my $i ( 0 .. $#$path ) {
					my @steps = @{ $path->[$i]{segment} };
					for my $j ( 0 .. $#steps ) {
						my $step = $steps[$j];
						if (   ( $j || $non_initial )
							&& $step->{step}
							&& !$step->{separator} )
						{
							confess
'every non-initial step must be preceded by one of the separators "/", "//", or "/>"';
						}
						confirm_separators( $step, $i ? 1 : $non_initial );
					}
				}
			}
			else {
				my $attribute = $ref->{attribute};
				if ($attribute) { confirm_separators( $attribute, 0 ) }
				else {
					my $predicate = $ref->{predicate};
					if ($predicate) {
						confirm_separators( $predicate, 0 );
					}
					else {
						confirm_separators( $_, $non_initial ) for values %$ref;
					}
				}
			}
		}
	}
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
	confess 'empty {x,y} quantifier ' . $enum->{''}
	  unless $start || $end;
	confess 'in {x,y} quantifier ' . $enum->{''} . ' end is less than start'
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
		default { confess "unexpected type $type" }
	}
}

# group operators and arguments according to operator precedence ! > & > ` > ||
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
						for my $op (qw(! & ` ||)) {
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
												operator => $op eq '`'
												? '^'
												: $op,
												args => [
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
		default { confess "unexpected type $type" }
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
		when ('one') { return '`' }
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
	if ( $s eq $e ) {
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
