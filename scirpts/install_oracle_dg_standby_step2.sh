echo "配置tnsnames.ora"
su -c 'cat <<EOF >${ORACLEPATH}/oracle/oracle/product/12c/db_1/network/admin/tnsnames.ora
${ORACLESID} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${outputs.oracle_primary.instanceCode})(PORT = 1521))
    )
    (CONNECT_DATA =
       (SERVICE_NAME = ${ORACLESID})
    )
  )

${ORACLESID}_stby =
  (DESCRIPTION =
    (UT=A)
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${outputs.oracle_standby.instanceCode})(PORT = 1521))
    )
    (CONNECT_DATA =
     (SERVICE_NAME = ${ORACLESID})
    )
  )
EOF' - ${ORACLEUSER}

echo "配置listener.ora"
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

echo "配置standby配置文件"
su -c 'cat <<EOF >${ORACLEPATH}/install/stby.ora
*.db_name="${ORACLESID}"
EOF' - ${ORACLEUSER}

su -c 'orapwd file=${ORACLEPATH}/oracle/oracle/product/12c/db_1/dbs/orapw${ORACLESID} password=${ORACLEPASSWD} format=12 entries=10 force=y' - ${ORACLEUSER}

su -c 'mkdir -p ${ORACLEPATH}/oracle/oracle/admin/${ORACLESID}/adump' - ${ORACLEUSER}


su -c 'sqlplus "/as sysdba"  <<EOF
startup nomount pfile="${ORACLEPATH}/install/stby.ora";
quit;
EOF' - ${ORACLEUSER}