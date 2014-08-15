use v5.14;
use warnings;

package Attean::IRI 0.001 {
	use Moose;
	use IRI 0.003;
	
	extends 'IRI';
	
	has 'ntriples_string'	=> (is => 'ro', isa => 'Str', lazy => 1, builder => '_ntriples_string');

	with 'Attean::API::IRI';
	with 'Attean::API::BlankOrIRI';

	around BUILDARGS => sub {
		my $orig 	= shift;
		my $class	= shift;
		if (scalar(@_) == 1) {
			return $class->$orig(value => shift);
		}
		return $class->$orig(@_);
	};
	
	sub as_string {
		my $self	= shift;
		return $self->abs;
	}
}

1;
