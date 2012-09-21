#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(param header);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use LWP::UserAgent;
use Safe;

# authorization token
use constant AUTH_TOKEN => "RANDOM_PASSWORD";

# dreamhost API
use constant DH_API_KEY => "DREAHOST_API_KEY";

# pushover API
use constant PSH_APP_TOKEN => "PUSHOVER_APP_TOKEN";
use constant PSH_USER_KEY => "PUSHOVER_USER_KEY";

my $agent = LWP::UserAgent->new;


sub api_call {    
    my $cmd       = shift;      
    my $post_data = shift;
        
    $post_data->{key}     = DH_API_KEY;
    $post_data->{cmd}     = $cmd;
    $post_data->{format} = 'perl';
    
    my $resp = $agent->post("https://api.dreamhost.com/", $post_data);                   
    return new Safe()->reval($resp->decoded_content) if ($resp->is_success);
    croak "Dreamhost API call $cmd failed: " . $resp->status_line;
}

sub pushover_notification {       
    my $title = shift;
	my $message = shift;

    my $resp = $agent->post(
		"https://api.pushover.net/1/messages", 
		[
			"token" => PSH_APP_TOKEN,
			"user" => PSH_USER_KEY,			
			"title" => $title,
			"message" => $message,			
		]);	              
		
    croak "Pushover API call failed: " . $resp->status_line if ($resp->is_success);
}

sub delete_record {
    my $record = shift;   
    
    my $result = api_call("dns-remove_record", {
        record => $record->{record},
        type   => $record->{type},
        value  => $record->{value}
    });

    croak "dns-remove_record failed: " . $result->{data} if ($result->{result} ne "success");    
    return $result;
}

sub create_record {
    my $domain = shift;
    my $ip     = shift;
            
    my $result = api_call("dns-add_record", { 
        record => $domain,
        type   => 'A',
        value  => $ip,
        comment => "Dynamic DNS entry for $domain"    
    }); 

    croak "dns-add_record failed: " . $result->{data} if ($result->{result} ne "success");   
    return $result;
}

sub get_record {
    my $domain = shift;

    my $records = api_call("dns-list_records", {})->{data};    
    for my $record (@{ $records }) {             
        if ($record->{record} eq $domain) {
            croak "record '$domain' is not editable!" unless ($record->{editable});
            return $record;
        }
    }
    return undef;
}

sub main {
    my $auth   = param('auth');
    my $domain = param('domain');
    my $ip     = $ENV{'REMOTE_ADDR'};
    
    croak "Authoization token invalid." unless ($auth eq AUTH_TOKEN);
    croak "Domain cannot be null." unless ($domain);
    croak "IP address cannot be null." unless ($ip);
    
    print header();
    print "<p>Updating $domain address (A) record to $ip ...</p>";
    
    my $record = get_record($domain);
            
    if ($record) {        
        if ($record->{value} ne $ip) {
            print "<p>$domain is already registered, updating.</p>";
            delete_record($record);
            create_record($domain, $ip);
			pushover_notification("DNS Record Updated", "The DNS address record '$domain' has been updated to $ip");
        } else {
            print "<p>$domain does not need updating.</p>";
        }
    } else {
        print "<p>$domain has not been registered, creating new entry.</p>";
        create_record($domain, $ip);
		pushover_notification("DNS Record Created", "Created DNS address record '$domain' for $ip");
    }
    
    print "<p><strong>Done.</strong></p>";
}

# go!
main();
