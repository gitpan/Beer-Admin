# $File: //member/autrijus/Beer-Admin/lib/Beer/Win32.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 4476 $ $DateTime: 2003/02/28 15:58:00 $

package Beer::Win32;

use strict;
use vars qw(@EXPORT $VERSION %ARGS @CLEAN @ISA);
use Exporter;

$VERSION    = '0.01';
@EXPORT	    = qw(check_nmake);
@ISA	    = 'Exporter';

# check if we can run some command
sub can_run {
    my $command = shift;

    # absoluate pathname?
    return $command if (-x $command or $command = MM->maybe_command($command));

    require Config;
    for my $dir (split /$Config::Config{path_sep}/, $ENV{PATH}) {
        my $abs = File::Spec->catfile($dir, $command);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

# determine if the user needs nmake, and download it if needed
sub check_nmake {
    require Config;
    return unless (
        $Config::Config{make} =~ /^nmake\b/i and
        $^O eq 'MSWin32'             and
        !can_run('nmake')
    );

    print "The required 'nmake' executable not found, fetching it...\n";

    use File::Basename;
    my $rv = get_file(
	url	    => 'ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe',
	local_dir   => dirname($^X),
	size	    => 51928,
	run	    => 'nmake15.exe /o > nul',
	check_for   => 'nmake.exe',
	remove	    => 1,
    );

    if (!$rv) {
	die << '.';

------------------------------------------------------------------------

Since you are using Microsoft Windows, you will need the 'nmake' utility
before installation. It's available at:

    ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe

Please download the file manually, save it to a directory in %PATH (e.g.
C:\WINDOWS\COMMAND), then launch the MS-DOS command line shell, "cd" to
that directory, and run "nmake15.exe" from there; that will create the
'nmake.exe' file needed by this module.

You may then resume the installation process described in README.

------------------------------------------------------------------------
.
    }
}

# fetch nmake from Microsoft's FTP site
sub get_file {
    my %args = @_;

    my ($scheme, $host, $path, $file) = 
	$args{url} =~ m|^(\w+)://([^/]+)(.+)/(.+)| or return;

    return unless $scheme eq 'ftp';

    unless (eval { require Socket; Socket::inet_aton($host) }) {
        print "Cannot fetch 'nmake'; '$host' resolve failed!\n";
        return;
    }

    use Cwd;
    my $dir = getcwd;
    chdir $args{local_dir} or return if exists $args{local_dir};

    $|++;
    print "Fetching '$file' from $host. It may take a few minutes... ";

    if (eval { require Net::FTP; 1 }) {
        # use Net::FTP to get pass firewall
        my $ftp = Net::FTP->new($host, Passive => 1, Timeout => 600);
        $ftp->login("anonymous", 'anonymous@example.com');
        $ftp->cwd($path);
        $ftp->binary;
        $ftp->get($file) or die $!;
        $ftp->quit;
    }
    elsif (can_run('ftp')) {
        # no Net::FTP, fallback to ftp.exe
        require FileHandle;
        my $fh = FileHandle->new;

        local $SIG{CHLD} = 'IGNORE';
        unless ($fh->open("|ftp.exe -n")) {
            warn "Couldn't open ftp: $!";
            chdir $dir; return;
        }

        my @dialog = split(/\n/, << ".");
open $host
user anonymous anonymous\@example.com
cd $path
binary
get $file $file
quit
.
        foreach (@dialog) { $fh->print("$_\n") }
        $fh->close;
    }
    else {
        print "Cannot fetch '$file' without a working 'ftp' executable!\n";
        chdir $dir; return;
    }

    return if exists $args{size} and -s $file != $args{size};
    system($args{run}) if exists $args{run};
    unlink($file) if $args{remove};

    print(((!exists $args{check_for} or -e $args{check_for})
	? "done!" : "failed! ($!)"), "\n");
    chdir $dir; return !$?;
}

1;
