#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(param header);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use LWP::UserAgent;

use constant APP_TOKEN => "PUSHOVER_APP_TOKEN";


sub pushover_notification {
	my $user    = shift;
	my $message = shift;

	my $resp = LWP::UserAgent->new()->post(
		"https://api.pushover.net/1/messages", 
		[
			"token" => APP_TOKEN,
			"user" => $user,
			"message" => $message,
		]);
	
        croak "Pushover API call failed: " . $resp->status_line if ($resp->is_success);
}

sub main {	
	my $user = param('user');
	my $message = param('message');

	croak "User key is required" unless $user;
	croak "Pushover message body is required" unless $message;

        pushover_notification($user, $message);
        print "<p><strong>success</strong></p>";
}

# go!
main();
