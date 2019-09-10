#!/usr/bin/perl -w
#+------------------------------------------------------------------------+
#| Filename: mysqlbackups.pl                                              |
#| Authors : Patricio Rojas Ortiz - patricio-rojaso@outlook.com           |
#| Purpose : Backup of all mysql database. Generate file with format name |
#|           basename-date-time.sql. You must add it to the cron schema of|
#|           your server.                                                 |
#| Platform: Linux                                                        |
#| Previous: Set your local password with the following command           |
#| mysql_config_editor set --login-path=local --host=localhost \          |
#|                                  --user=username --password            |
#|                                                                        | 
#| Packages: mysql-server. No additional packages/libraries are required  |
#| Revision: 2019-04-17 19:56:33                                          |
#| Version : 2019-04-17 19:56:33                                          |
#+------------------------------------------------------------------------+
#| This source file is subject to the The MIT License (MIT)               |
#| that is bundled with this package in the file LICENSE.txt.             |
#|                                                                        |
#| If you did not receive a copy of the license and are unable to         |
#| obtain it through the world-wide-web, please send an email             |
#| to patricio-rojaso@outlook.com so we can send you a copy immediately.  |
#+------------------------------------------------------------------------+

use constant CONS_VERSION     => '2019-04-17 19:56:33';

# You must customize the following lines according to your installation
use constant CONS_PATH_TMP    => '/tmp';
use constant CONS_PATH_OUTPUT => '/home/pro/repository/mysql/';

use strict;
use warnings;
use diagnostics;

my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst );
my ( @a_databases, $dir_tmp , $command, $databases, $tmp );

  &sub_copyright();

  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year = $year+1900;
  $mon  = $mon + 1;

  if (defined $ARGV[0]) {
    $databases = $ARGV[0];
  } else {
    $databases = CONS_PATH_OUTPUT;
  }

  print "Backup to: ", $databases, "\n\n";

  $command    = "/bin/echo \"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA\" > ".CONS_PATH_TMP."/sql.sql  2>&1" ;
  system($command) == 0 or warn "system $command failed: $?";

  $command    = "/usr/bin/mysql --login-path=local < ".CONS_PATH_TMP."/sql.sql > ".CONS_PATH_TMP."/databases.txt  2>&1" ;
  system($command) == 0 or warn "system $command failed: $?";

  $dir_tmp = CONS_PATH_TMP ."/". sprintf("%04d%02d%02d-%02d%02d%02d",  $year, $mon, $mday, $hour, $min, $sec);

  $command = "mkdir -p ". $dir_tmp;
  system($command) == 0 or warn "system $command failed: $?";

  $tmp = &sub_file_load( CONS_PATH_TMP. "/databases.txt" );
  @a_databases  = split( "\n", $tmp );

  foreach  $tmp ( @a_databases ) {
        if ( length( $tmp )>0) {
            if ($tmp  !~ /SCHEMA_NAME|information_schema|sys|performance_schema|mysql/) {
                print "backups of database:($tmp)\n";
                $command   = "/usr/bin/mysqldump --login-path=local -B $tmp --single-transaction --flush-logs >" .$dir_tmp. "/$tmp.sql 2>&1";
                system($command)== 0 or warn "system $command failed: $?";
            }
        }
  }

  $databases = $databases . sprintf("%04d%02d%02d-%02d%02d%02d",  $year, $mon, $mday, $hour, $min, $sec);
  $command   = "tar zcf $databases.tar.gz $dir_tmp  2>&1";
  system($command) == 0 or warn "system $command failed: $?";

  $command   = "rm -rf $dir_tmp  2>&1";
  system($command) == 0 or warn "system $command failed: $?";

	$command   = "rm -rf ".CONS_PATH_TMP."/sql.sql  2>&1";
	system($command) == 0 or warn "system $command failed: $?";

	$command   = "rm -rf ".CONS_PATH_TMP."/databases.txt  2>&1";
	system($command) == 0 or warn "system $command failed: $?";

  printf "done\n";
  exit;

# ------------------------------------------------------------------------------
sub sub_copyright(){

    print "\nmysqlbackups.pl V".CONS_VERSION.", Copyright 2016\n\n";

}

# ------------------------------------------------------------------------------

sub sub_file_load(){
  my $filename = shift;
  my ( @thisfile, $sl_return, $sl_line );

  print "sub_file_load: $filename ...\n";

  open (FILE, $filename);
  @thisfile = <FILE>;
  close (FILE);

  $sl_return = "";
  foreach $sl_line (@thisfile) {

          $sl_return = $sl_return .  $sl_line;
  }

  print "sub_file_load: ".length($sl_return)." Bytes of $filename\n";
  return $sl_return ;

}
