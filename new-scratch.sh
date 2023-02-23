#!/bin/sh

PACKAGE_ID=04t4W000002kay6QAA
PERMSET_NAME=my_permset_name

while [ ! -n "$ORG_NAME"  ] 
do
	echo "🐱  Please enter a name for your scratch org:"
	read ORG_NAME
done

echo "🐱  Building your org, please wait."
sfdx force:org:create -w 10 -f config/project-scratch-def.json --setalias ${ORG_NAME} --durationdays 7 --setdefaultusername --json --loglevel DEBUG

if [ "$?" = "1" ] 
then
	echo "🐱 Can't create your org."
	exit
fi 

echo "🐱 Scratch org created."
echo "🐱 Installing package with ID ${PACKAGE_ID}, please wait"

RES=`sfdx force:package:install --package ${PACKAGE_ID} -u ${ORG_NAME} --json -w 10`

if [ "$?" = "1" ] 
then
	echo "🐱  Can't install this package."
	exit
fi

INSTALL_ID=`echo ${RES} | egrep -o '"Id":"(.*?)"' | cut -d : -f 2 | tr -d '"'`
echo "🐱 Package install in progress, please wait."

STATUS=init
while [ $STATUS != 'SUCCESS' ]
do
	RES=`sfdx force:package:install:get -i ${INSTALL_ID} -u ${ORG_NAME} --json`
	STATUS=`echo ${RES} | egrep -o '"Status":".*?"' | cut -d : -f 2 | tr -d '"' `
	echo "🍺  Install status is ${STATUS}. Please wait."
	sleep 10
done

echo "🐱  Pushing the code, please wait. It may take a while."

sfdx force:source:push -u ${ORG_NAME}

if [ "$?" = "1" ]
then 
	echo "🐱  Can't push your source."
	exit 
fi

echo "🐱  Code is pushed successfully."

sfdx force:user:permset:assign -n ${PERMSET_NAME} -u ${ORG_NAME} --json

if [ "$?" = "1" ]
then
	echo "🐱  Can't assign the permission set."
	exit 
fi	

echo "🐱  Permission set is assigned successfully."

sfdx force:org:open -u ${ORG_NAME}