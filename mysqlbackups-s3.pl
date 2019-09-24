#!/usr/bin/perl -w
#+------------------------------------------------------------------------+
#| Filename: mysqlbackups-s3.pl                                              |
#| Authors : Patricio Rojas Ortiz - patricio-rojaso@outlook.com           |
#| Purpose : Backup of all mysql database. Generate file with format name |
#|           basename-date-time.sql. You must add it to the cron schema of|
#|           your server.                                                 |
#| Platform: Linux                                                        |
#| Previous: Set your local password with the following command           |
#| mysql_config_editor set --login-path=local --host=localhost \          |
#|                                  --user=username --password            |
#|                                                                        |
#| Packages: apt-get install libamazon-s3-perl                            |
#|           mysql-server                                                 |
#|           No additional packages/libraries are required                |
#|                                                                        |
#| Revision: 2019-09-17 11:52:11                                          |
#| Version : 2019-09-17 11:52:11                                          |
#+------------------------------------------------------------------------+
#| This source file is subject to the The MIT License (MIT)               |
#| that is bundled with this package in the file LICENSE.txt.             |
#|                                                                        |
#| If you did not receive a copy of the license and are unable to         |
#| obtain it through the world-wide-web, please send an email             |
#| to patricio-rojaso@outlook.com so we can send you a copy immediately.  |
#+------------------------------------------------------------------------+

use constant CONS_VERSION     => '2019-09-17 11:52:11';

# Begin -- You must customize the following lines according to your installation
use constant CONS_PATH_TMP    => '/tmp';
use constant CONS_PATH_OUTPUT =>'/home/ubuntu/backups/mysql/';
use constant CONS_EXPIRES_DAYS => 3; # Backups are maintained for 3 days
use constant CONST_BUCKET_S3 => 'your-buckets-name-of-amazon-s3';
# End   -- You must customize the following lines according to your installation

use strict;
use warnings;
use diagnostics;
use Amazon::S3;
use DateTime;
use DateTime::Format::Strptime;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';

my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst );
my ( @a_databases, $dir_tmp , $command, $databases, $key, $tmp, $expires);

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

  $tmp = &sub_file_load(CONS_PATH_TMP. "/databases.txt" );
  @a_databases  = split( "\n", $tmp );

  foreach my $tmp ( @a_databases ) {
        if ( length( $tmp )>0) {
            if ($tmp  !~ /SCHEMA_NAME|information_schema|sys|performance_schema|mysql/) {
                print "backups of database:($tmp)\n";
                $command   = "/usr/bin/mysqldump --login-path=local -B $tmp --single-transaction --flush-logs >" .$dir_tmp. "/$tmp.sql 2>&1";
                system($command)== 0 or warn "system $command failed: $?";
            }
        }
  }

  # Key amazon
  $key       = sprintf("%04d-%02d-%02d",  $year, $mon, $mday) . '.tar.gz';

  # database contains the path where it will be physically stored on disk
  $databases = $databases . $key;
  $key = 'mysql/'. $key;

  $command   = "tar zcf $databases $dir_tmp  2>&1";
  system($command) == 0 or warn "system $command failed: $?";

  $command   = "rm -rf $dir_tmp  2>&1";
  system($command) == 0 or warn "system $command failed: $?";

	$command   = "rm -rf ".CONS_PATH_TMP."/sql.sql  2>&1";
	system($command) == 0 or warn "system $command failed: $?";

	$command   = "rm -rf ".CONS_PATH_TMP."/databases.txt  2>&1";
	system($command) == 0 or warn "system $command failed: $?";

  # ----------------------------------------------------------------------------
  #                                                               S3 connection
  # ----------------------------------------------------------------------------


  my $access_key = $ENV{'ACCESS_KEY'};
  my $secret_key = $ENV{'SECRET_KEY'};

  my $s3 = Amazon::S3->new({
          aws_access_key_id     => $access_key,
          aws_secret_access_key => $secret_key,
          retry                 => 1,
  });

  my $bucket = $s3->bucket(CONST_BUCKET_S3);

  # ----------------------------------------------------------------------------
  #          Remove from Amazon S3, the oldest backup CONS_EXPIRES_DAYS days ago
  #
  # Another way is the administrative one (in Amazon S3), adding rules for the
  # life cycle of the files.
  # ----------------------------------------------------------------------------

  $expires = sprintf("%04d-%02d-%02d",  $year, $mon, $mday); # fecha actual
  $expires = &getDateOld($expires, CONS_EXPIRES_DAYS);
  $expires = 'mysql/'. $expires . '.tar.gz';

  # check if resource exists (a previous backup made).
  if ($bucket->head_key($expires)) {
    # delete key from bucket
    $bucket->delete_key($expires);
  }

  # ----------------------------------------------------------------------------
  #                                              Upload backup file to Amazon S3
  # ----------------------------------------------------------------------------

  # Upload archivo a s3 bucket.

  $bucket->add_key_filename(
    $key, # Key
    $databases, # Filename
    {
      content_type => "application/x-compressed",
    }
  );

  printf "done\n";
  exit;

# ------------------------------------------------------------------------------
sub sub_copyright()
{

    print "\nmysqlbackups-s3.pl V".CONS_VERSION.", Copyright 2019 Patricio Rojas Ortiz\n\n";

}

# ------------------------------------------------------------------------------
# Returns the file content of variable $filename
sub sub_file_load()
{
  my $filename = shift;
  my ($fd, $return, @thisfile);

  print "sub_file_load: $filename ...\n";

  open ($fd,'<', $filename);
  @thisfile = <$fd>;
  close ($fd);

  $return = "";
  foreach my $line (@thisfile) {
          $return = $return .  $line;
  }

  print "sub_file_load: " . length($return)." Bytes of $filename\n";
  return $return ;

}

## ------------------------------------------------------------------------------
# With the current date variable $date, we get the date passed a number of days
# variable $days with format yyyy-mm-dd, to delete a backup file in s3
# S3 prefix mysql/yyyy-mm-dd.tar.gz

sub getDateOld()
{
    my ($date, $days)=@_;
    my ($dt, $sqlcode, $datetime, $strp);

    $days = $days * -1;

    $strp = DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%d'
    );

    # convert date to datetime format
    $dt = $strp->parse_datetime($date);

    return $dt->add(days => $days )->strftime("%Y-%m-%d");

}
## -----------------------------------------------------------------------------
