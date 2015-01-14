package App::ProxyMate::TCPClient;

use strict;
use warnings;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;


has host    => (is=> 'rw');
has port    => (is=> 'rw');

has hdl     => (is=> 'rw');
has on_read => (is=> 'rw'); 


no Mouse;
__PACKAGE__->meta->make_immutable;

sub connect:method {
	my $self = shift;
	my $cb = pop ;
	croak "Need callback" unless ref $cb eq 'CODE';

	tcp_connect $self->host, $self->port, sub {
		my ($fh) = @_
			or $cb->( undef, "Connection failed: $!");
		$self->save_handle($fh);
		$cb->($self);
	}

}

sub save_handle {
	my $self = shift;
	my $fh   = shift;
	
	my $hdl; $hdl = AnyEvent::Handle->new(
		fh       => $fh,
		on_error => sub {
			my ($hdl, $fatal, $msg) = @_;
			AE::log error => $msg;
			$hdl->destroy;
		},
		on_read => sub {
			my $handle = shift;
			$self->on_read->( $handle->{rbuf} );
			$handle->{rbuf}='';
		},
	);
	$self->hdl($hdl);
}

sub send:method {
	my $self = shift;
	my $data = shift;

	$self->hdl->push_write($data);
	
}

1;

