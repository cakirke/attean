use Test::Modern;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean;
use Attean::RDF;
use Type::Tiny::Role;
use AtteanX::Parser::Turtle::Constants;

my $constraint	= 'Attean::API::Triple';

my $s	= blank('x');
my $t	= blank('y');
my $p	= iri('http://example.org/p');
my $q	= iri('http://example.org/q');
my $r	= iri('http://example.org/r');
my $o1	= Attean::Literal->integer(1);
my $o2	= Attean::Literal->integer(2);
my $o3	= Attean::Literal->new(value => '3');
my $o4	= Attean::Literal->new(value => '火星', language => 'ja');

my $t1	= triple($s, $p, $o1);
my $t2	= triple($s, $p, $o2);
my $t3	= triple($s, $q, $o3);
my $t4	= triple($t, $r, $o4);

subtest 'turtle with object-list' => sub {
	my $ser	= Attean->get_serializer('Turtle')->new();
	does_ok($ser, 'Attean::API::Serializer');
	does_ok($ser, 'Attean::API::TripleSerializer');
	isa_ok($ser, 'AtteanX::Serializer::Turtle');

	my $expected	= <<"END";
_:x <http://example.org/p> 1 , 2 .
END
	
	{
		my $i	= Attean::ListIterator->new(values => [$t1, $t2], item_type => $constraint);
		my $data1	= $ser->serialize_iter_to_bytes($i);
		my $data2	= $ser->serialize_list_to_bytes($t1, $t2);
	
		is($data1, $expected, 'serialize_iter_to_bytes');
		is($data1, $data2, 'serialize_list_to_bytes');
	}

	{
		my $i	= Attean::ListIterator->new(values => [$t1, $t2], item_type => $constraint);
		my $data	= '';
		open(my $fh, '>', \$data);
		$ser->serialize_iter_to_io($fh, $i);
		close($fh);
	
		is($data, $expected, 'serialize_iter_to_io');
	}

	{
		my $i	= Attean::ListIterator->new(values => [$t1, $t2], item_type => $constraint);
		my $data	= '';
		open(my $fh, '>', \$data);
		$ser->serialize_list_to_io($fh, $t1, $t2);
		close($fh);
	
		is($data, $expected, 'serialize_iter_to_io');
	}
};

subtest 'turtle with predicate-object list' => sub {
	my $ser	= Attean->get_serializer('Turtle')->new();
	my $expected	= <<'END';
_:x <http://example.org/p> 1 , 2 ;
    <http://example.org/q> "3" .
_:y <http://example.org/r> "火星"@ja .
END
	
	my $i	= Attean::ListIterator->new(values => [$t1, $t2, $t3, $t4], item_type => $constraint);
	my $data1	= $ser->serialize_iter_to_bytes($i);
	my $data2	= $ser->serialize_list_to_bytes($t1, $t2, $t3, $t4);

	is($data1, $expected, 'serialize_iter_to_bytes');
	is($data1, $data2, 'serialize_list_to_bytes');
};

subtest 'turtle with prefix namespace declaration' => sub {
	my $map		= URI::NamespaceMap->new( { foaf => iri('http://xmlns.com/foaf/0.1/') } );
	my $ser = Attean->get_serializer('Turtle')->new( namespaces => $map );
	my $expected	= <<'END';
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
_:x <http://example.org/p> 1 , 2 .
END

	my $iter	= Attean::ListIterator->new(values => [$t1, $t2], item_type => 'Attean::API::Triple');
	my $turtle	= $ser->serialize_iter_to_bytes($iter);
	is($turtle, $expected, 'serialize_iter_to_bytes');
};

subtest 'turtle with prefix namespace declaration and use' => sub {
	my $map		= URI::NamespaceMap->new( { ex => iri('http://example.org/') } );
	my $ser = Attean->get_serializer('Turtle')->new( namespaces => $map );
	my $expected	= <<'END';
@prefix ex: <http://example.org/> .
_:x ex:p 1 , 2 .
END

	my $iter	= Attean::ListIterator->new(values => [$t1, $t2], item_type => 'Attean::API::Triple');
	my $turtle	= $ser->serialize_iter_to_bytes($iter);
	is($turtle, $expected, 'serialize_iter_to_bytes');
};

subtest 'escaping' => sub {
	my @tokens;
	my $dq	= literal('"');
	my $sq	= literal("'");
	my $bq	= literal(q["']);
	
	@tokens	= $dq->sparql_tokens->elements;
	expect(shift(@tokens), STRING1D, ['"'], 'double quote');

	@tokens	= $sq->sparql_tokens->elements;
	expect(shift(@tokens), STRING1D, ["'"], 'single quote');
	
	@tokens	= $bq->sparql_tokens->elements;
	expect(shift(@tokens), STRING1D, [q["']], 'double and single quotes');
	
	my $ser = Attean->get_serializer('Turtle')->new();
	my @triples	= map { triple(iri('s'), iri('p'), $_) } ($dq, $sq, $bq);
	my $iter	= Attean::ListIterator->new(values => \@triples, item_type => 'Attean::API::Triple');
	my $turtle	= $ser->serialize_iter_to_bytes($iter);
	my $expected	= qq[<s> <p> "\\"" , "'" , "\\"'" .\n];
	is($turtle, $expected, 'serialize_iter_to_bytes');
};


done_testing();

sub expect {
	my $token	= shift;
	my $type	= shift;
	my $values	= shift;
	my $name	= shift // '';
	if (length($name)) {
		$name	= "${name}: ";
	}
	is($token->type, $type, "${name}token type");
	is_deeply($token->args, $values, "${name}token values");
}