#!/bin/bash
source $(dirname $0)/include/jackhammerAPI.sh

if [ ! -d Analysis_Folder ]; then
	mkdir Analysis_Folder
	
	# Throw notice and quit!
  echo "Jackhammer Text Miner: Analytics"
  echo "================================"
	echo "Analysis_Folder not found. Creating one for you!"
	echo "Please place your folders, with PDF's, in the Analysis_Folder folder."
	echo ""
	echo "Then run this script again."
	exit

fi

cd Analysis_Folder

# determine if empty, throw error
if [ ! "$(ls -A .)" ]; then
	echo "Jackhammer Text Miner: Analytics"
	echo "================================"
	echo "Analysis_Folder is empty. Please place your folders, with PDF's, in the Analysis_Folder folder."
	echo ""
	echo "Then run this script again."
	exit
fi

ListOfFolders=`ls -l -d */ | grep -v include | awk '{print $9}' | tr -d "/"`

for Folder in $ListOfFolders; do
	#echo "[DEBUGGGING] Current PWD: "`pwd`
	#echo "Processing Folder: "$Folder
	cd $Folder
	#echo "[DEBUGGGING] Current PWD: "`pwd`
	CleanAndSetupFolders
	GetPDFs
	Because
	cp $FinalReportPDF ../
	#echo "Names: "$i
	cd ..
	ReportNameNStuff=$Folder"_"$FinalReportPDF
	mv $FinalReportPDF $ReportNameNStuff
	echo "============================================="
done
cd ..
