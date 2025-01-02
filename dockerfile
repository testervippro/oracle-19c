# Use the official Oracle Linux 7 base image
FROM oraclelinux:7-slim

# Set environment variables
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/19c/dbhome_1 \
    ORACLE_SID=ORCLCDB \
    ORACLE_PDB=ORCLPDB1 \
    PATH=$ORACLE_HOME/bin:$PATH

# Install dependencies
RUN yum -y install oracle-database-preinstall-19c unzip && \
    yum clean all

# Copy Oracle 19c installation files
COPY LINUX.X64_193000_db_home.zip /tmp/
COPY master.zip /tmp/

# Unzip the Oracle installation files
RUN unzip /tmp/LINUX.X64_193000_db_home.zip -d $ORACLE_HOME && \
    rm -f /tmp/LINUX.X64_193000_db_home.zip

# Run the Oracle installer
RUN $ORACLE_HOME/runInstaller -silent -ignorePrereq -waitforcompletion \
    -responseFile $ORACLE_HOME/install/response/db_install.rsp && \
    rm -rf $ORACLE_HOME/install

# Create the database
RUN $ORACLE_HOME/bin/dbca -silent -createDatabase \
    -templateName General_Purpose.dbc \
    -gdbname $ORACLE_SID -sid $ORACLE_SID \
    -responseFile NO_VALUE \
    -characterSet AL32UTF8 \
    -sysPassword oracle \
    -systemPassword oracle \
    -createAsContainerDatabase true \
    -numberOfPDBs 1 \
    -pdbName $ORACLE_PDB \
    -pdbAdminPassword oracle \
    -databaseType MULTIPURPOSE \
    -automaticMemoryManagement false \
    -totalMemory 2048

# Unzip the HR sample schema
RUN unzip /tmp/master.zip -d /tmp/ && \
    rm -f /tmp/master.zip

# Install the HR sample schema
RUN $ORACLE_HOME/bin/sqlplus sys/oracle@ORCLPDB1 as sysdba <<EOF
    @/tmp/db-sample-schemas-master/hr_main.sql
    exit;
EOF

# Expose ports
EXPOSE 1521 5500

# Set the entrypoint
CMD ["/bin/bash", "-c", "$ORACLE_HOME/bin/dbstart $ORACLE_HOME && tail -f $ORACLE_HOME/startup.log"]
