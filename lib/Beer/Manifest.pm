# $File: //member/autrijus/Beer-Admin/lib/Beer/Manifest.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 4480 $ $DateTime: 2003/02/28 16:37:37 $

package Beer::Manifest;

use strict;
use vars qw(@EXPORT $VERSION @ISA);
use Cwd;
use Exporter;

$VERSION    = '0.02';
@EXPORT	    = qw(update_manifest);
@ISA	    = 'Exporter';

sub update_manifest {
    my ($manifest, $manifest_path, $relative_path) = read_manifest();
    return unless -w $manifest_path;

    my $manifest_changed = 0;

    my %manifest;
    for (@$manifest) {
        my $path = $_;
        chomp $path;
	$path =~ s/\s.*//;
        $path =~ s/^\.[\\\/]//;
        $path =~ s/[\\\/]/\//g;
        $manifest{$path} = 1;
    }

    for (<inc/Beer.pm>, <inc/Beer/*.pm>) {
        my $filepath = $_;
        $filepath = "$relative_path/$filepath"
          if length($relative_path);
	next unless -f $filepath;
        unless (defined $manifest{$filepath}) {
            print "Updating your MANIFEST file:\n"
              unless $manifest_changed++;
            print "  Adding '$filepath'\n";
	    my $tabs = "\t" x (5 - (int(length($filepath)) / 8));
            push @$manifest, "$filepath${tabs}Support file - Not installed\n";
            $manifest{$filepath} = 1;
        }
    }

    if ($manifest_changed) {
        open MANIFEST, "> $manifest_path" 
          or die "Can't open '$manifest_path' for output:\n$!";
        print MANIFEST for @$manifest;
        close MANIFEST;
    }
}

sub read_manifest {
    my $manifest = [];
    my $manifest_path = '';
    my $relative_path = '';
    my @relative_dirs = ();
    my $cwd = Cwd::cwd();
    my @cwd_dirs = File::Spec->splitdir($cwd);
    while (@cwd_dirs) {
        last unless -f File::Spec->catfile(@cwd_dirs, 'Makefile.PL');
        my $path = File::Spec->catfile(@cwd_dirs, 'MANIFEST');
        if (-f $path) {
            $manifest_path = $path;
            last;
        }
        unshift @relative_dirs, pop(@cwd_dirs);
    }
    unless (length($manifest_path)) {
        die "Can't locate the MANIFEST file for '$cwd'\n";
    }
    $relative_path = join '/', @relative_dirs
      if @relative_dirs;

    open MANIFEST, $manifest_path 
      or die "Can't open $manifest_path for input:\n$!";
    @$manifest = <MANIFEST>;
    close MANIFEST;

    return ($manifest, $manifest_path, $relative_path);
}

1;
