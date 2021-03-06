#!/bin/sh

# List of databases to be backed up separated by space
dblist="database1 database2 database3..."

# Directory for backups
backupdir=/backup/mysql_dumps

# Number of versions to keep
numversions=7

# Full path for MySQL hotcopy command
# Please put credentials into /root/.my.cnf
#hotcopycmd=/usr/bin/mysqlhotcopy
hotcopycmd="/usr/bin/mysqldump --lock-tables --databases"

# Create directory if needed
mkdir -p "$backupdir"
if [ ! -d "$backupdir" ]; then
   echo "Invalid directory: $backupdir"
   exit 1
fi

# Hotcopy begins here
echo "Dumping MySQL Databases..."
RC=0
for database in $dblist; do
   echo
   echo "Dumping $database ..."
   mv "$backupdir/$database.gz" "$backupdir/$database.0.gz" 2> /dev/null
   $hotcopycmd $database | gzip > "$backupdir/$database.gz"

   RC=$?
   if [ $RC -gt 0 ]; then
     continue;
   fi

   # Rollover the backup directories
   rm -fr "$backupdir/$database.$numversions.gz" 2> /dev/null
   i=$numversions
   while [ $i -gt 0 ]; do
     mv "$backupdir/$database.`expr $i - 1`.gz" "$backupdir/$database.$i.gz" 2> /dev/null
     i=`expr $i - 1`
   done
done

if [ $RC -gt 0 ]; then
   echo "MySQL Dump failed!"
   exit $RC
else
   # Hotcopy is complete. List the backup versions!
   ls -l "$backupdir"
   echo "MySQL Dump is complete!"
fi
exit 0
