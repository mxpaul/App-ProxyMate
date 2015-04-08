package App::ProxyMate::TCPClient;

use strict;
use warnings;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

use App::ProxyMate::TCPConnection;


has host           => (is=> 'rw');
has port           => (is=> 'rw');

has connection     => (is=> 'rw');
has on_read        => (is=> 'rw'); 
has on_client_gone => (is=> 'rw'); 


no Mouse;
__PACKAGE__->meta->make_immutable;

sub connect:method {
	my $self = shift;
	my $cb = pop ;
	croak "Need callback" unless ref $cb eq 'CODE';

	tcp_connect $self->host, $self->port, sub {
		my ($fh) = @_
			or $cb->( undef, "Connection failed: $!");
		$self->connection(
			App::ProxyMate::TCPConnection->new(fh=>$fh)
		);
		$self->connection->on_client_gone(sub { $self->on_client_gone->(@_) if $self->on_client_gone });
		$self->connection->on_read(sub { $self->on_read->(@_) if $self->on_read });
		$cb->($self);
	}

}

sub send:method {
	my $self = shift;
	$self->connection->send(@_);
}

1;

