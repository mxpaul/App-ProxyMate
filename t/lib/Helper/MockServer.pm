package Helper::MockServer;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::MockTCPServer qw/:all/;

has timeout => (is=> 'rw', default => 1); 
has timer   => (is=> 'rw',); 
has server  => (is=> 'rw',); 

has connection  => (is =>'rw', required => 1);

sub BUILD {
	my $self = shift;

	$self->timer( AE::timer $self->timeout,0, sub { 
		undef $self->timer; 
		$self->server->finished_cv->croak("tcp mock server exited for timeout");
	});

	my $connections;
	if ( ref $self->connection eq 'ARRAY' ) {
		$connections = [ # Expected connections sequence
			#[ # first connection
				$self->connection,
			#],
		],
	} else {
		die "Fix this logic first!"
	}

	$self->server (AnyEvent::MockTCPServer->new(connections => $connections));

}


no Mouse;
__PACKAGE__->meta->make_immutable;

