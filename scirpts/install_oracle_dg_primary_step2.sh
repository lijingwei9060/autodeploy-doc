echo "配置standby日志文件组"
su -c 'sqlplus "/as sysdba" <<EOF
ALTER DATABASE FORCE LOGGING;
ALTER DATABASE  flashback on;
ALTER SYSTEM SWITCH LOGFILE;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 100M;
alter system set STANDBY_FILE_MANAGEMENT=AUTO scope=both;
alter system set FAL_SERVER=${ORACLESID}_stby scope=both ;
quit;
EOF' - ${ORACLEUSER}

echo "配置tnsnames.ora"
su -c 'cat <<EOF >>${ORACLEPATH}/oracle/oracle/product/12c/db_1/network/admin/tnsnames.ora
${ORACLESID}_stby =
  (DESCRIPTION =
    (UT=A)
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${outputs.oracle_standby.instanceCode})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED) (SERVICE_NAME = ${ORACLESID})
    )
  )
EOF' - ${ORACLEUSER}

su -c 'cat <<EOF >>${ORACLEPATH}/oracle/grid/product/12c/grid/network/admin/listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLESID}_DGMGRL)
      (ORACLE_HOME = ${ORACLEPATH}/oracle/oracle/product/12c/db_1)
      (SID_NAME = ${ORACLESID})
    )
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLESID})
      (ORACLE_HOME = ${ORACLEPATH}/oracle/oracle/product/12c/db_1)
      (SID_NAME = ${ORACLESID})
    )
  )
EOF' - ${GRIDUSER}

su -c 'lsnrctl reload' - ${GRIDUSER}