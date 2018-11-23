#! /bin/sh
su -c 'srvctl stop  database -db ${ORACLESID} ;srvctl start database -db ${ORACLESID} -startoption mount' - ${ORACLEUSER}
su -c 'dgmgrl sys/${ORACLEPASSWD}@${ORACLESID} <<EOF
SHOW CONFIGURATION;
quit;
EOF' - ${ORACLEUSER}