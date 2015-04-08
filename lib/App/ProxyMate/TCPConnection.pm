package App::ProxyMate::TCPConnection;

use strict;
use warnings;

use Mouse;
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

use App::ProxyMate::TCPConnection;



has fh             => (is=> 'rw', required => 1);
#has peer_host      => (is=> 'rw', required => 1);
#has peer_port      => (is=> 'rw', required => 1);
has hdl            => (is=> 'rw');
has on_read        => (is=> 'rw'); 
has on_client_gone => (is=> 'rw'); 

sub BUILD {
	my $self = shift;
	$self->save_handle($self->fh);
}

no Mouse;
__PACKAGE__->meta->make_immutable;

sub save_handle {
	my $self = shift;
	#my $fh   = shift;
	
	my $hdl; $hdl = AnyEvent::Handle->new(
		fh       => $self->fh,
		on_error => sub {
			my ($hdl, $fatal, $msg) = @_;
			carp "FIXME: not covered by tests";
			$self->on_client_gone->($msg) if $self->on_client_gone;
			$hdl->destroy;
		},
		on_read => sub {
			my $handle = shift;
			$self->on_read->( $handle->{rbuf} );
			$handle->{rbuf}='';
		},
		on_eof => sub {
			my ($hdl) = @_;
			$self->on_client_gone->('EOF received') if $self->on_client_gone;
			#$hdl->destroy;
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

