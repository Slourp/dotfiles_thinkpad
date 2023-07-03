#!/bin/bash

# Define variables
SSH_PORT=9025
SSH_USER=ubuntu
SSH_HOST=54.38.184.83
BACKUP_DIR=/home/ubuntu/backups
MYSQL_CONTAINER_NAME=PEPITE_MYSQL
MYSQL_USER=user
MYSQL_PASSWORD=password
MYSQL_DATABASE=main

# Function to list all backups
list_backups() {
   ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "ls -1tr $BACKUP_DIR/PEPITE_MYSQL-main*.sql.gz" | awk -F/ '{print $NF}'
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

fix_aliases() {
   declare -A updates=(
       [1]="testv2.promoplus.fr:testv2.traefik.me"
       [2]="www.myskemastore.promoplus.fr:skema.traefik.me"
       [3]="boutique-exco.promoplus.fr:execo.traefik.me"
       [5]="www.eshopdemo.pepitegoodies.com:eshopdemo.traefik.me"
       [6]="www.commandes-pge.promoplus.fr:pge.traefik.me"
       [7]="asdia.pepitegoodies.com:asdia.traefik.me"
       [8]="www.pepitebypromoplus.com:pepitebypromoplus.traefik.me"
       [10]="goodies.suez.com:suez.traefik.me"
       [11]="laboutique.cftc.fr:cftc.traefik.me"
       [12]="eshopdemo1.pepitegoodies.com:eshopdemo1.traefik.me"
       [13]="elivie.pepitegoodies.com:elivie.traefik.me"
       [16]="www.radiofrance.pepitegoodies.com:radiofrance.traefik.me"
       [18]="www.boutique.partnaire.fr:partnaire.traefik.me"
       [19]="eshopdemo6.pepitegoodies.com:eshopdemo6.traefik.me"
       [20]="gieorpilyon.pepitegoodies.com:gieorpilyon.traefik.me"
       [21]="boutique.grdf.fr:grdf.traefik.me"
       [22]="goodies.paprec.com:paprec.traefik.me"
       [24]="eshopdemo2.pepitegoodies.com:eshopdemo2.traefik.me"
       [25]="eshopdemo5.pepitegoodies.com:eshopdemo5.traefik.me"
       [26]="gigroup.pepitegoodies.com:gigroup.traefik.me"
       [27]="boutique.grdf.debug.pepite.shop:grdf.traefik.me"
       [28]="goodies.paprec.debug.pepite.shop:paprec.traefik.me"
	   [29]="laboutique.cftc.debug.pepite.shop:cftc.traefik.me"
       [30]="www.boutique.partnaire.debug.pepite.shop:partnaire.traefik.me"
       [31]="boutique.suez.debug.pepite.shop:suez.traefik.me"
       [34]="mirakl.pepite.shop:mirakl.traefik.me"
       [38]="nexity.pepite.shop:nexity.traefik.me"
   )

   # Loop through the updates and execute the SQL statement for each one
   for id in "${!updates[@]}"; do
       url=${updates[$id]}
       sql="UPDATE boutique_aliases SET url = REPLACE(url, '${url%:*}', '${url#*:}') WHERE id = ${id};"
       docker exec $MYSQL_CONTAINER_NAME mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "$sql"
   done
}

# Parse command line arguments
case $1 in
--fix-aliases)
   fix_aliases
   ;;
--list)
   list_backups
   ;;
--restore)
   remote_file="$BACKUP_DIR/$(basename "$2")"
   local_file="/tmp/$(basename "$2")"
   scp -P $SSH_PORT "$SSH_USER@$SSH_HOST:$remote_file" "$local_file" && restore_backup "$local_file" && rm "$local_file"
   ;;
--latest)
   latest_backup="$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST 'ls -1tr /home/ubuntu/backups/PEPITE_MYSQL-main*.sql.gz | tail -n 1')"
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
   echo "    --fix-aliases           Fix domain aliases in the MySQL database"
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
