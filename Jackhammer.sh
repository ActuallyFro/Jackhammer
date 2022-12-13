#!/bin/bash
source $(dirname $0)/include/jackhammerAPI.sh

SetupMainFolder

cd Analysis_Folder
CheckMainFolderEmpty

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
