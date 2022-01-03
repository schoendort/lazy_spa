#!/usr/bin/perl
use LoxBerry::System;
use CGI;
use JSON;
use LoxBerry::JSON;

my $cfgfile = "$lbpconfigdir/config.json";


my $cgi = CGI->new;
my $json = $cgi->param('POSTDATA');

my $userMail = decode_json($json);

my $jsonobj = LoxBerry::JSON->new();
my $cfg = $jsonobj->open(filename => $cfgfile );

$cfg->{mail} = $userMail->{mail};
$cfg->{password} = $userMail->{password};

$jsonobj->write();

print $cgi->header(
			-type => 'application/json',
			-charset => 'utf-8',
			-status => '204 NO CONTENT',
					);	
