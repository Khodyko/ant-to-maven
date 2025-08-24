#!/bin/sh

# Последовательно выолняет следующие действия:
# 1) Собирает проект
# 2) Чистит deployment
# 3) Чистит tmp и log
# 4) Копирует сборку в wildfly
# 5) Запускает wildfly

# для подготовки скрипта для себя ЗАМЕНИТЕ ПУТИ!

# shows issue of build
fexit(){
	echo $*
	exit 1
}

SERVER_HOME="/work/report/ant_to_maven/wildfly-26.1.3.Final/"

ANT_BUILD_PATH="/work/report/ant_to_maven/solutions/";
BUILDED_EAR_FILE_PATH_1="/work/report/ant_to_maven/development/assembly/ear/modules_anttest_reader.ear"
SERVER_DEPLOYMENTS_FOLDER=$SERVER_HOME"/standalone/deployments/";
SERVER_TMP_FOLDER=$SERVER_HOME"standalone/tmp/";
SERVER_LOG_FOLDER=$SERVER_HOME"standalone/log/";
STANDALONE_PATH=$SERVER_HOME"bin/standalone.sh";

echo "********* ANT Clean Started **********";
ant -f $ANT_BUILD_PATH  || fexit "MAVEN Building Error";
echo ant_test installed;
echo "********* DELETE ear FILES **********";
rm -rf $SERVER_DEPLOYMENTS_FOLDER*.war
rm -rf $SERVER_DEPLOYMENTS_FOLDER"archive"
echo "********* DELETE ear FILES FINISHED **********";
echo "********* CLEAN TMP and LOG FOLDERS **********";
rm -rf $SERVER_TMP_FOLDER*;
rm -rf $SERVER_LOG_FOLDER*;
echo "********* CLEAN TMP and LOG FOLDERS FINISHED **********";
echo "********* Copy files to server deployments **********";
cp $BUILDED_EAR_FILE_PATH_1  $SERVER_DEPLOYMENTS_FOLDER"modules_anttest_reader.ear";
echo "********* Files in deployments folder **********";
echo "********* WildFly StartRunning **********";
sh $STANDALONE_PATH --debug 8787 -b=0.0.0.0
echo "********* WildFly FinishRunning **********";

