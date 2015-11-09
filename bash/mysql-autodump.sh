#!/bin/bash

set -e

gzip_enable=0
destdir='/tmp'

usage()
{
cat << EOF
Usage: $0 --user=mysql_user --password=mysql_password --database=mysql_database
Dumps a MySQL database with the schema and data

OPTIONS:
  -u, --user=user            MySQL user
  -p, --password=password    MySQL password
  -d, --database=database    Name of the database
  -o, --output-dir           Write dump file to this directory (Default: /tmp)
  -z, --gzip                 gzip the dumpfile ( Default: disabled )
  -h, --help                 Prints this message
EOF
}

#Parse arguments
if [ "$#" -eq 0 ] ; then
    usage
    exit 2
fi
PARAMS=`getopt -n $0 -o u:p:d:o:hz --long user:,password:,database:,output_dir:,help,gzip -- "$@"`
eval set -- "$PARAMS"
while true ; do
    case "$1" in
        -u|--user) mysql_user=$2; shift 2 ;;
        -p|--password) mysql_password=$2 ; shift 2 ;;
        -d|--database) mysql_database=$2 ; shift 2 ;;
        -o|--output-dir) destdir=$2 ; shift 2 ;;
        -z|--gzip) gzip_enable=1 ; shift ;;
        -h|--help) usage ; exit 1 ;;
        --) shift ; break ;;
        *) usage ; exit 2 ;;
    esac
done

#Error checking
error_state=0;

if [ -z "$mysql_user" ] ; then
    echo "You MUST specify MySQL user !"
    error_state=1
fi

if [ -z "$mysql_password" ] ; then
    echo "You MUST specify MySQL password !"
    error_state=1
fi

if [ -z "$mysql_database" ] ; then
    echo "You MUST specify MySQL database !"
    error_state=1
fi

if [ ! -d "$destdir" ] ; then
    echo "Destination directory doesn't exist !"
    error_state=1    
fi

if [ "$error_state" = 1 ] ; then
    echo "There are errors in your arguments, exiting."
    exit 2
fi

dumpfile=$destdir'/'$mysql_database'-'$(date +%Y%m%d%H%M)'.sql'

mysqldump --user=$mysql_user --password=$mysql_password $mysql_database > $dumpfile
if [ "$gzip_enable" = 1 ] ; then
    gzip $dumpfile
    dumpfile=$dumpfile".gz"
fi
echo $dumpfile
exit 0
