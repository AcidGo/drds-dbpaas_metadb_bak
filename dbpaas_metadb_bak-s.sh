#!/bin/bash
# Author: AcidGo
# Version: 0.0.1
# Usage: Through mysqldump to backup dbpaas-metadb, then docker cp it outter and remove it inner.


LOGFILE=/home/dbpaas_slave_bak/dbpaas_slave_bak.log


function logging {
    echo -n $(date +"%Y-%m-%d %H:%M:%S") >> ${LOGFILE} && echo $* >> ${LOGFILE}
}


logging "[INFO] ========== Start script =========="


# DB_MASTER=$(sudo docker ps --format="{{.Names}}"| grep dbpaas-metadb-master_dbpaas | cut -d/ -f2)
DB_SLAVE=$(sudo docker ps --format="{{.Names}}"| grep dbpaas-metadb-slave_dbpaas | cut -d/ -f2)


SLAVE_BAK_FILE="dbpaas_metadb_slave-$(date +%F).sql.gz"
logging "[INFO] Begin mysqldump slave backup: ${SLAVE_BAK_FILE}."
sudo docker exec ${DB_SLAVE} bash -c "mysqldump -uroot -h127.1 -A | gzip > /tmp/${SLAVE_BAK_FILE}"


if [ "$?" == "0" ]; then
    slave_inner_size=$(sudo docker exec ${DB_SLAVE} bash -c "du /tmp/${SLAVE_BAK_FILE}" | awk '{print $1}')
    sudo docker cp ${DB_SLAVE}:/tmp/${SLAVE_BAK_FILE} /home/dbpaas_slave_bak
    if [ ${slave_inner_size} == $(du /home/dbpaas_slave_bak/${SLAVE_BAK_FILE} | awk '{print $1}') ]; then
        logging "[INFO] Slave backup ${SLAVE_BAK_FILE} Sucessfully."
    else
        logging "[ERROR] Slave backup du is not equene."
    fi
    logging "[INFO] Begin remove inner slave backup."
    sudo docker exec ${DB_SLAVE} bash -c "alias rm='rm' && rm -f /tmp/${SLAVE_BAK_FILE}"
    [ $? != 0 ] && logging "[ERROR] Remove slave_bak_file has error."
else
    logging "[ERROR] Docker exec mysqldump failed.Remove inner slave_bak_file."
    sudo docker exec ${DB_SLAVE} bash -c "[ -f /tmp/${SLAVE_BAK_FILE} ] && alias rm='rm' && rm -f /tmp/${SLAVE_BAK_FILE}"
    [ $? != 0 ] && logging "[ERROR] Remove inner slave_bak_file has error."
fi