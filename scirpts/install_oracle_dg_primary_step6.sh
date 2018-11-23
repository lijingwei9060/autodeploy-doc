su -c 'sqlplus "/as sysdba"  <<EOF
ALTER SYSTEM SET dg_broker_start=true;
quit;
EOF' - ${ORACLEUSER}

su -c 'sqlplus "sys/${ORACLEPASSWD}@${ORACLESID}_stby as sysdba"  <<EOF
ALTER SYSTEM SET dg_broker_start=true;
quit;
EOF' - ${ORACLEUSER}
sleep 60


su -c 'dgmgrl sys/${ORACLEPASSWD}@${ORACLESID} <<EOF
CREATE CONFIGURATION my_dg_config AS PRIMARY DATABASE IS ${ORACLESID} CONNECT IDENTIFIER IS ${ORACLESID};
ADD DATABASE ${ORACLESID}_stby AS CONNECT IDENTIFIER IS ${ORACLESID}_stby MAINTAINED AS PHYSICAL;
ENABLE CONFIGURATION;
edit database ${ORACLESID}_stby set property ArchiveLagTarget=0;
edit database ${ORACLESID}_stby set property StandbyFileManagement=AUTO;
edit database ${ORACLESID}_stby set property LogArchiveMinSucceedDest=1;
edit database ${ORACLESID}_stby set property LogArchiveMaxProcesses=4;
edit database ${ORACLESID}_stby set property DataGuardSyncLatency=0;
SHOW CONFIGURATION;
quit;
EOF' - ${ORACLEUSER}