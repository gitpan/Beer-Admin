# $File: //member/autrijus/Beer-Admin/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 4480 $ $DateTime: 2003/02/28 16:37:37 $

use lib 'lib';	# for this module only -- you don't need it
use inc::Beer;

check_nmake();
WriteMakefile();
