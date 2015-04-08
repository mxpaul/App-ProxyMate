#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib::abs qw( ../lib );

use Data::Dumper;
use EV;
use AnyEvent;
use feature 'say';
use Carp;
use Getopt::Long;

use App::ProxyMate::TCPClient;

my $proxy = {
	host => '209.66.193.186',
	port => 8080,
};

my $NL="\012\015";

my $verbose;

sub success{
	my $msg = shift;
	my $cb  = shift; croak "need callback" unless ref $cb;
	say $msg if $verbose;
	$cb->(1);
}

sub failure {
	my $msg = shift;
	my $cb  = shift; croak "need callback" unless ref $cb;
	say $msg if $verbose;
	$cb->(0);
}

GetOptions('host=s' => \$proxy->{host}, 'port=s' => \$proxy->{port}, 'v' => \$verbose );
my $cv = AE::cv;
my $client = App::ProxyMate::TCPClient->new( %$proxy);
$client->connect(sub {
	if ( my $connection = shift ) {
		$connection->on_read(sub {
			if ( my $reply = shift) {
				if ( $reply =~ m{^Location:\s+http://www.google.com}xm ) {
					success "Proxy is alive", $cv;
				} else {
					failure "Location header not found, proxy is dead", $cv;
				}
			} else {
				failure 'Empty reply, proxy is dead', $cv;
			}
		});
		$connection->send("GET http://google.com HTTP/1.1$NL$NL");
	} else {
		my $msg = shift;
		failure "Proxy is dead: $msg" , $cv;
	}
});

my $proxy_ok = $cv->recv;
exit ($proxy_ok?0:1);

