package App::ProxyMate::TCPClient;

use strict;
use warnings;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::Socket;


has host => (is=> 'rw');
has port => (is=> 'rw');


no Mouse;
__PACKAGE__->meta->make_immutable;

sub connect:method {
	my $self = shift;
	my $cb = pop ;
	croak "Need callback" unless ref $cb eq 'CODE';

	tcp_connect $self->host, $self->port, sub {
		my ($fh) = @_
			or $cb->( undef, "Connection failed: $!");
		$cb->($fh);

	}

}

1;

