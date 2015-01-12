#!/usr/bin/env perl

#	use FindBin qw($Bin);
#	use lib "$Bin";

use Test::Class::Moose::Load 't/lib';
use Test::Class::Moose::Runner;
Test::Class::Moose::Runner->new->runtests;
