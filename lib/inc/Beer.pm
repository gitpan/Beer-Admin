# $File: //member/autrijus/Beer-Admin/lib/inc/Beer.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 4474 $ $DateTime: 2003/02/28 14:30:11 $

package inc::Beer;
use strict;
use vars qw($VERSION $PACKAGE $DIR $FILE);

# the brand we're drinking
BEGIN {
    $VERSION = '0.10';
    $DIR = $PACKAGE = __PACKAGE__;
    $DIR =~ s!::!/!g;
    $FILE = "$DIR.pm";
}

# fill a brand if we don't have one
require Beer::Admin unless -f $FILE;

if (!$INC{"Beer.pm"}) {
    # reload a bottle of beer
    delete $INC{$FILE};
    unshift @INC, 'inc';
    require Beer;
}
else {
    # drink all brands on the tray
    local *TRAY;
    my @Loaded;
    if (opendir(TRAY, $DIR)) {
	while (my $brand = readdir(DIR)) {
	    next unless $brand =~ /\.pm$/i;

	    package main;
	    require "$Beer::DIR/$brand";
	    "Beer::$brand"->import;
	}
	closedir(TRAY);
    }

    # remove all beers and start anew
    *purge_self = sub {
	foreach my $file (<$DIR/*.pm>, $FILE) {
	    unlink $file or die "Cannot remove $file:\n$!";
	}
	my @parts = split('/', $DIR);
	foreach my $i (reverse(0 .. $#parts)) {
	    my $path = join('/', @parts[0..$i]);
	    rmdir $path or last;
	}
    };

    # get new brands if we need more to drink
    package main;
    *AUTOLOAD = sub {
	require Beer::Admin;
	goto &Beer::Admin::drink;
    }
}

"Enjoy your breakfast!";
