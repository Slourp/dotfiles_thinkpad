#!/bin/bash

# Define variables
SSH_PORT=9025
SSH_USER=ubuntu
SSH_HOST=54.38.184.83
BACKUP_DIR=/home/ubuntu/backups
MYSQL_CONTAINER_NAME=MAGIC_LINK_MYSQL
MYSQL_USER=user
MYSQL_PASSWORD=password
MYSQL_DATABASE=main

# Function to list all backups
list_backups() {
   ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "ls -1tr $BACKUP_DIR/MAGIC_LINK_MYSQL-main*.sql.gz" | awk -F/ '{print $NF}'
}

# Function to restore a specific backup file
restore_backup() {
   local backup_file=$1
   local temp_file=$(mktemp)

   # Restore the backup file using the docker command
   gunzip -c "$backup_file" | docker exec -i "$MYSQL_CONTAINER_NAME" mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"

   # Check if the restore was successful
   if [[ $? -eq 0 ]]; then
       echo "Restore completed successfully."
   else
       echo "Restore failed."
       exit 1
   fi

   # Delete the temporary file created on the local machine
   rm -f "$temp_file"
}

# Parse command line arguments
case $1 in
--list)
   list_backups
   ;;
--restore)
   remote_file="$BACKUP_DIR/$(basename "$2")"
   local_file="/tmp/$(basename "$2")"
   scp -P $SSH_PORT "$SSH_USER@$SSH_HOST:$remote_file" "$local_file" && restore_backup "$local_file" && rm "$local_file"
   ;;
--latest)
   latest_backup="$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST 'ls -1tr /home/ubuntu/backups/MAGIC_LINK_MYSQL-main*.sql.gz | tail -n 1')"
   remote_file="$BACKUP_DIR/$(basename "$latest_backup")"
   local_file="/tmp/$(basename "$latest_backup")"
   scp -P $SSH_PORT "$SSH_USER@$SSH_HOST:$remote_file" "$local_file" && restore_backup "$local_file" && rm "$local_file"
   ;;
--help)
   echo "Usage: ./script.sh [options]"
   echo "Options:"
   echo "    --list                  List all backup files"
   echo "    --restore <file>        Restore a specific backup file"
   echo "    --latest                Restore the latest backup file"
   echo "    --help                  Display this help message"
   ;;
*)
   echo "Invalid option: $1"
   echo "Use the --help option for more information."
   exit 1
   ;;
esac

# If no options are provided, show an error message and exit
if [[ $# -eq 0 ]]; then
   echo "No options provided. Use the --help option for more information."
   exit 1
fi
