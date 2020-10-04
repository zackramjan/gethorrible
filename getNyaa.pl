#!/usr/bin/perl
use XML::Simple;
use XML::LibXML;
use Data::Dumper;
use File::HomeDir;
use File::Basename;
use Date::Parse;

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
	next if $line =~ /^\#/;
	my @a = split(/,/,$line);
	$match{$a[0]}=$a[1];
}

for my $m (keys %match)
{
	$m =~ s/\"/\\\"/g;
	my $xml = `wget -O - \"https://nyaa.si/?page=rss&q=$m&c=1_2&f=0&magnets&s=id&o=desc\"` ;
	my $ref = XML::LibXML->load_xml(string => $xml);
	foreach my $item ($ref->findnodes('/rss/channel/item')) 
	{
		my  $title = $item->findvalue('./title');
		my  $link = $item->findvalue('./link');
		my  $infohash = $item->findvalue('./nyaa:infoHash');
		my  $pubdate = str2time($item->findvalue('./pubDate'));
		last if ($pubdate < time() - 864000) && ! $ARGV[1]; 

		$link =~ m/dn=(.+?)\&/; 
		my $magFile = $1;	

		if( ! -e "$match{$m}/$r" && ! -e "$match{$m}/$r"  && ! -e "$trackingDir/$infohash")
		{	
			print "search $m\n\tGrabbing $title magnet to dir $match{$m} \n";
			runcmd("$ADDCMD -p $match{$m} \"$link\""); 
			open my $outfile, ">$trackingDir/$infohash";
			print $outfile "$title\n$link\n$infohash\n$pubdate\n";
			close $outfile;
		}
	}
}
for my $f (glob ("$trackingDir/*"))
{
	$f =~ s/\'/\\\'/g;
	runcmd("$DELCMD \\\"" . basename($f) . "\\\"") if (time - ( stat($f))[9]) > 3600;
	unlink $f if (time - ( stat($f))[9]) > 1000000;
}

sub runcmd{
        my $cmd=shift @_;
        my $caller=(caller(1))[3];
        print STDERR "$caller\t$cmd\n";
        system($cmd);
}
