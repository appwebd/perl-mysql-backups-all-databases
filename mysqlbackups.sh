#!/bin/bash
# Sample file to establish in cronjob, the backup in amazon S3

cd /home/ubuntu/backups
rm /home/ubuntu/backups/mysql/*
rm /home/ubuntu/backups/mysql.tar.gz

# Define the following authorization values ​​for your Amazon S3 configuration
# (required environment variables in mysqlbackups-s3.pl)

export ACCESS_KEY="YOUR-ACCESS-KEY"
export SECRET_KEY="YOUR-SECRET-KEY"

/home/ubuntu/bin/crontab/mysqlbackups-s3.pl

rm /home/ubuntu/backups/mysql/*
rm /home/ubuntu/backups/mysql.tar.gz
