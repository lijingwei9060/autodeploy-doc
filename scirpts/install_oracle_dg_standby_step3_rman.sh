sleep 120
su -c 'rman TARGET sys/${ORACLEPASSWD}@${ORACLESID} AUXILIARY sys/${ORACLEPASSWD}@${ORACLESID}_stby <<EOF
DUPLICATE TARGET DATABASE
FOR STANDBY
FROM ACTIVE DATABASE
DORECOVER
SPFILE
SET db_unique_name="${ORACLESID}_stby" COMMENT "Is standby"
NOFILENAMECHECK;
quit;
EOF' - ${ORACLEUSER}
#重启数据库
su -c 'sqlplus "/as sysdba"  <<EOF
shutdown immediate;
quit;
EOF' - ${ORACLEUSER}

su -c 'srvctl add database -db ${ORACLESID} -o ${ORACLEPATH}/oracle/oracle/product/12c/db_1 -p ${ORACLEPATH}/oracle/oracle/product/12c/db_1/dbs/spfile${ORACLESID}.ora -r physical_standby -s "read only" ' - ${ORACLEUSER}
su -c 'srvctl start  database -db ${ORACLESID} -startoption mount' - ${ORACLEUSER}
sleep 60