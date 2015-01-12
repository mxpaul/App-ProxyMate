#!/usr/bin/env perl

package TestFor::ProxyMate;
use Test::Class::Moose;
use App::ProxyMate;

sub test_constructor {
	can_ok 'App::ProxyMate', 'new';
}

1;
