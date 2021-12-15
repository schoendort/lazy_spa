#!/usr/bin/perl

require HTTP::Request;

use LWP::UserAgent;
use Net::MQTT::Simple;
use Time::HiRes;
use LoxBerry::JSON;
use LoxBerry::IO;
use LoxBerry::Log;
use LoxBerry::System;

$ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;

$mqttConfig = LoxBerry::IO::mqtt_connectiondetails();

my $mqtt = Net::MQTT::Simple->new("$mqttConfig->{brokeraddress}");

$mqtt->login($mqttConfig->{brokeruser}, $mqttConfig->{brokerpass});

LOGSTART "Bestway Lazy-Spa plugin started";

LOGINF "$lbplogdir + $lbpconfigdir";

my $cfgfile = "$lbpconfigdir/config.json";

my $log = LoxBerry::Log->new (
    name => 'Bestway Lazy-Spa',
	filename => "$lbplogdir/lazyspa.log",
	append => 1,
	stdout => 1
);



my $jsonobj = LoxBerry::JSON->new();
my $cfg = $jsonobj->open(filename => $cfgfile );

$mqtt->subscribe("bestway/set", \&received);

while(1){
	$mqtt->tick();
	if(!$cfg->{mail} or !$cfg->{password}){
		LOGWARN "missing configuration";
	}elsif(!$cfg->{token}){
		getToken();
	}elsif(!$cfg->{deviceId}){
		getDeviceId();
	}else{
		LOGINF "have everything, fine";
		getCurrentState();
	}	
	Time::HiRes::sleep(10);
}

$mqtt->disconnect();

sub getToken{
	my $request = HTTP::Request->new(POST => 'https://euapi.gizwits.com/app/login');
	$request->header('Content-Type' => 'application/json');
	$request->header('X-Gizwits-Application-Id' => '98754e684ec045528b073876c34c7348');
	$request->content("{ \"username\": \"$cfg->{mail}\", \"password\": \"$cfg->{mail}\", \"lang\": \"en\" }");

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);	
	if($response->is_success){
		my $message = $response->decoded_content;
		LOGINF "Received reply: $message\n\n\n";
		my $fromjson = from_json($message);
		LOGINF "Token id is " . $fromjson->{'token'} . "\n";
		$cfg->{token} = $fromjson->{'token'};
		$jsonobj->write();
	}else{
		 die $response->status_line;
		LOGERR "Token request was not successful";
	}
}

sub getDeviceId{
	my $request = HTTP::Request->new(GET => 'https://euapi.gizwits.com/app/bindings?limit=20&skip=0');
	$request->header('X-Gizwits-Application-Id' => '98754e684ec045528b073876c34c7348');
	$request->header('X-Gizwits-User-token' => $cfg->{token});
	
	LOGINF "current token $cfg->{token}";

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	LOGINF "got response $response->is_success";	
	if($response->is_success){
		LOGINF "got response $response1";
		my $message = $response->decoded_content;
		LOGINF "Received reply: $message\n\n\n";
		my $fromjson = from_json($message);
		$cfg->{deviceId} = $fromjson->{devices}->[0]->{did};
		$jsonobj->write();
	}else{
		LOGERR "device request was not successful";
	}
}

sub getCurrentState(){
	my $request = HTTP::Request->new(GET => "https://euapi.gizwits.com/app/devdata/$cfg->{deviceId}/latest");
	$request->header('X-Gizwits-Application-Id' => '98754e684ec045528b073876c34c7348');

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	if($response->is_success){
		my $message = $response->decoded_content;
		LOGINF "Received reply: $message\n\n\n";
		my $fromjson = from_json($message);
		foreach my $attr (keys %{$fromjson->{attr}} ){
			if($attr ne 'temp_set_unit'){
				LOGINF "published";
				$mqtt->retain("bestway/$attr", $fromjson->{attr}->{$attr});
			}
		}
	}else{
		die $response->status_line;
		LOGERR "Token request was not successful";
	}
}

sub received 
{
	my ($topic, $message) = @_;
	LOGINF "Incoming message on topic $topic is: $message\n";
	my $request = HTTP::Request->new(POST => "https://euapi.gizwits.com/app/control/$cfg->{deviceId}");
	$request->header('Content-Type' => 'application/json');
	$request->header('X-Gizwits-Application-Id' => '98754e684ec045528b073876c34c7348');
	$request->header('X-Gizwits-User-token' => $cfg->{token});
	
	$request->content("{ \"attrs\" : $message }");

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	if($response->is_success){
		LOGINF "everything fine :)";
		getCurrentState();
	}else{
		 die $response->status_line;
		LOGERR "Token request was not successful";
	}
}

