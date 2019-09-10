# perl-mysql-backups-all-databases

Backup of all mysql database. Generate file with format name basename-date-time.sql.  You must add it to the cron schema of your server.

## Installation
```
git clone https://github.com/appwebd/perl-mysql-backups-all-databases.git
```

## Customize

You must customize the following in your favorite terminal (Or any DCL command prompt). Set your local password with the following command 

```

 mysql_config_editor set --login-path=local --host=localhost  --user=username --password 


```

## Schedule Tasks on Linux (using Crontab)
Do the following command in your terminal console.
```
sudo crontab -e

```

add the following (like example):
```
0 0 * * * /home/<user account>/bin/mysqlbackups.pl 2>&1 | mail -s "Cronjob ouput" yourname@yourdomain.com
```

## License
 mysqlbackups.pl is licensed under The MIT License (MIT). Which means that you can use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software. But you always need to state that Patricio Rojas Ortiz is the original author of this perl script.
