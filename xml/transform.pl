#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(param header);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use LWP::UserAgent;
use XML::XSLT;


sub get_complete_feed_url {	
	my $qs = "$ENV{'QUERY_STRING'}";			
	return substr($qs, index($qs, 'feed=') + 5);
}

sub get_feed_content {
	my $url = shift;
	
	my $agent = LWP::UserAgent->new;
	my $resp = $agent->get($url);       
	return $resp->decoded_content if ($resp->is_success);
	croak "Failed to fetch feed content: " . $resp->status_line;	
}

sub transform {
	my $xml = shift;
	my $xsl  = shift;
	
	my $xslt = XML::XSLT->new($xsl);
	my $output = $xslt->serve($xml);
	$xslt->dispose();		
	
	return $output;
}

sub main {	
	my $xslFileName = param('xsl');	
	
	croak "XSL file name is required" unless $xslFileName;
	croak "XML feed URL is required" unless param('feed');
		
	my $feedUrl = get_complete_feed_url();
	my $feedContent = get_feed_content($feedUrl);	
	my $output = transform($feedContent, $xslFileName);	
	
	print $output;
}

# go!
main();