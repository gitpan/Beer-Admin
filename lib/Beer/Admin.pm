# $File: //member/autrijus/Beer-Admin/lib/Beer/Admin.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 4480 $ $DateTime: 2003/02/28 16:37:37 $

package Beer::Admin;

use strict;
use vars qw($VERSION %Fridge);
$VERSION = '0.11';

my $FILE = ($inc::Beer::FILE || "inc/Beer.pm");
my $DIR  = ($inc::Beer::DIR  || "inc/Beer");
prepare() if $INC{$FILE} and not -f $FILE;

sub prepare {
    # prepare the tray
    my @parts = split('/', $FILE);
    foreach my $i (0 .. $#parts - 1) {
	my $path = join('/', @parts[0..$i]);
	print "Preparing $path\n";
	mkdir($path, 0777) unless -d $path;
    }

    fill($INC{$FILE} => $FILE);
}

sub fill {
    my ($beer, $tray) = @_;

    print "Filling $tray\n";

    local $/;
    open BEER, $beer or die $!;	    # take beer from the fridge
    open TRAY, "> $tray" or die $!; # put it to the tray
    binmode(BEER); binmode(TRAY);
    print TRAY <BEER>;
    close BEER; close TRAY;
}

sub drink {
    my $flavor = $main::AUTOLOAD;
    $flavor =~ s/^main:://;

    # scan through our tray to find
    scan_fridge() unless %Fridge;

    my $beers = $Fridge{$flavor}
	or die "Cannot find a brand with flavor $flavor";

    my $chosen = pick($flavor, $beers);
    my $tray = "$DIR/$chosen->{brand}.pm";
    mkdir $DIR unless -d $DIR;
    fill($chosen->{bottle} => $tray);

    {
	package main;
	require $tray;
	"Beer::$chosen->{brand}"->import;
    }

    goto &{$main::AUTOLOAD};
}

sub pick {
    # determine which brand to drink -- for now, just take the first
    my ($flavor, $beers) = @_;
    return $beers->[0];
}

sub scan_fridge {
    foreach my $inc (@INC) {
	next if $inc eq 'inc' or ref($inc);
	my $dir = "$inc/Beer";
	next unless -d $dir;

	local *DIR;
	opendir(DIR, $dir) or next;
	while (my $bottle = readdir(DIR)) {
	    next unless $bottle =~ /(.+)\.pm$/i;
	    taste($1, "$dir/$bottle") unless lc($1) eq 'admin';
	}
    }
}

sub taste {
    my ($brand, $bottle) = @_;
    {
	package _mouth;
	require $bottle;
	"Beer::$brand"->import; # just a bit of taste
	delete $INC{$bottle};
    }
    # now, analyze all flavors in _mouth
    while (my ($flavor, $molecule) = each(%_mouth::)) {
	next unless defined &{$molecule};
	push @{$Fridge{$flavor}}, {
	    brand   => $brand,
	    bottle  => $bottle,
	};
    }

    # wash our mouth clean
    %_mouth:: = ();

    # put the beer back
    require Symbol;
    Symbol::delete_package("Beer::$brand");

}

1;
