#!/usr/bin/perl
use XML::Simple;
use Data::Dumper;
use File::HomeDir;
use File::Basename;

my $trackingDir = File::HomeDir->my_home . "/.autoGet";
mkdir("$trackingDir") unless -e "$trackingDir";

my $toGetFile = $ARGV[0] || die "specify a csv with list of things to for RSS to match and dir to save to (ex: One Piece,one_piece)\n";
-e $toGetFile  || die "specify a csv with list of things to for RSS to match and dir to save to (ex: One Piece,one_piece)\n";

$ADDCMD = "deluge-console add";
$DELCMD = "deluge-console pause";
$DELAGE = 1200;

my %match;
open(IN,"<$toGetFile");
while(my $line=<IN>)
{
	chomp $line;
	next unless $line =~ /,/;
	my @a = split(/,/,$line);
	$match{$a[0]}=$a[1];
}




for my $m (keys %match)
{
	my $xml = `wget -O - \"https://nyaa.si/?page=rss&q=$m&c=0_0&f=0&magnets\"` ;
	my $ref = XMLin($xml, ForceArray => 0, KeyAttr => "title");
	$torrents = $ref->{"channel"}->{item};
	for my $r (keys %{$torrents})
	{
		print "search $m\n\tGrabbing $r magnet to dir $match{$m} \n";
		if( ! -e "$match{$m}/$r" && ! -e "$trackingDir/$r")
		{	
			runcmd("$ADDCMD -p $match{$m} \"$torrents->{$r}->{link}\""); 
			runcmd("touch \"$trackingDir/$r\"");
		}
	}
}
for my $f (glob ("$trackingDir/*"))
{
	$f =~ s/\'/\\\'/g;
	runcmd("$DELCMD \\\"" . basename($f) . "\\\"") if (time - ( stat($f))[9]) > 3600;
	unlink $f if (time - ( stat($f))[9]) > 864000;
}


sub runcmd{
        my $cmd=shift @_;
        my $caller=(caller(1))[3];
        print STDERR "$caller\t$cmd\n";
        system($cmd);
}
