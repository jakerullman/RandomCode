#!/bin/bash

set -e

usage()
{
cat << EOF
Usage: $0 --user=mysql_user --password=mysql_password --from=mysql_database --to=mysql_database
This script copies the data (and only the data) from a MySQL database to another MySQL database 

OPTIONS:
  -u, --user=user            MySQL user (a user that has privileges on both tables)
  -p, --password=password    MySQL password
  -f, --from=database        Name of the source database
  -t, --to=database          Name of the destination database
  -h, --help                 Prints this message
EOF
}

#Parse arguments
if [ "$#" -eq 0 ] ; then
    usage
    exit 2
fi

PARAMS=`getopt -n $0 -o u:p:f:t:h --long user:,password:,from:,to:,help -- "$@"`
eval set -- "$PARAMS"
while true ; do
    case "$1" in
        -u|--user) mysql_user=$2; shift 2 ;;
        -p|--password) mysql_password=$2 ; shift 2 ;;
        -f|--from) mysql_database_from=$2 ; shift 2 ;;
        -t|--to) mysql_database_to=$2 ; shift 2 ;;
        -h|--help) usage ; exit 1 ;;
        --) shift ; break ;;
        *) usage ; exit 2 ;;
    esac
done

#Error checking
error_state=0;

if [ "$mysql_user" = '' ] ; then
    echo "You MUST specify MySQL user !"
    error_state=1
fi

if [ "$mysql_password" = '' ] ; then
    echo "You MUST specify MySQL password !"
    error_state=1
fi

if [ "$mysql_database_from" = '' ] ; then
    echo "You MUST specify a source database !"
    error_state=1
fi

if [ "$mysql_database_to" = '' ] ; then
    echo "You MUST specify a destination database !"
    error_state=1
fi

if [ "$error_state" = 1 ] ; then
    echo "There are errors in your arguments, exiting."
    exit 2
fi

dump_command="mysql-datadump -u ${mysql_user} -p ${mysql_password} -d ${mysql_database_from}"
dumpfile=$($dump_command)
#Save old data
backup_file='/tmp/'$mysql_database_to'-save-'$(date +%Y%m%d%H%M)'.sql'
mysqldump --user=$mysql_user --password=$mysql_password $mysql_database_to > $backup_file
#Erase old data
TABLES=$(mysql -u $mysql_user -p$mysql_password $mysql_database_to -e 'show tables' | awk '{ print $1}' | grep -v '^Tables' )
for t in $TABLES
do
    mysql -u $mysql_user -p$mysql_password $mysql_database_to -e "SET foreign_KEY_CHECKS=0; delete from $t"
done
echo $dumpfile

mysql -u $mysql_user -p $mysql_password $mysql_database_to < $dumpfile 
