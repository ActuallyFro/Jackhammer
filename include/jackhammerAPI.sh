#!/bin/bash

############################################
#Design

#1. Find a list of PDF's to convert to text, remove .pdf, save list to array --> Names[]
#2. Convert all PDF's to Txt (pdftotext)--> Save as YYYY-MM-DD_NAMEofFILE.txt
#3. Replace all spaces with '\n' (tr) --> Save to YY-MM-DD_NAMEofFILE_list.txt
#4. Apply Dictionary Filter to remove undesired words (grep et al.)--> Save to  YYYY-MM-DD_NAMEofFILE_list_Filter_FILTERNAME.txt
#5. Record PDF Information (pdfinfo)--> Save to YYYY-MM-DD_NAMEofFILE_Info.txt

############################################

############################################
#Settings/Variables
Verbose= true
Start_time=$(date +%s.%N)

ConvertedDocsPath=`date --iso-8601`"_01_Converted_Documents"
ReportPath_MostWords=`date --iso-8601`"_02_MostWords_Files"
ReportPath_ContextWords=`date --iso-8601`"_03_ContextWords_Files"
Filter1="Words2Remove"
FinalReport=`date --iso-8601`"_Final_Report.txt"
FinalReportPDF=`date --iso-8601`"_Final_Report.pdf"
PerFileStats=`date --iso-8601`"_PerFile_Report.txt"
LogFile="Log_MostUsedWords.log"

GlobalList=$ConvertedDocsPath"/Global_List.txt"
GlobalListFiltered=$ReportPath_MostWords"/"`date --iso-8601`"_Global_List_Filtered_"$Filter1".txt"
GlobalListFiltered_Summary=$ReportPath_MostWords"/"`date --iso-8601`"_Global_List_Filtered_"$Filter1"_Summary.txt"
GlobalListFiltered_UniqueWords=$ReportPath_MostWords"/"`date --iso-8601`"_Global_List_Filtered_"$Filter1"_UniqueWords.txt"


CleanAndSetupFolders(){
	#Clean up any past executions:
	rm -rf $ConvertedDocsPath"/"
	rm -rf $ReportPath_MostWords"/"
	rm -rf $ReportPath_ContextWords"/"
	rm -f $FinalReport
	rm -f $FinalReportPDF
	rm -f $PerFileStats

	mkdir -p $ReportPath_MostWords
	mkdir -p $ReportPath_ContextWords
	mkdir -p $ConvertedDocsPath
}

CheckForNeededCmds(){
	# check for `pdftotext`
	if ! command -v pdftotext &> /dev/null
	then
		echo "Jackhammer Text Miner: Analytics"
		echo "================================"
		echo "'pdftotext' not found!"
		echo ""
		echo "Try installing it with:"
		echo "sudo apt-get install -y poppler-utils"
		exit
	fi
}



SetupMainFolder(){
if [ ! -d Analysis_Folder ]; then
	mkdir Analysis_Folder
	
  echo "Jackhammer Text Miner: Analytics"
  echo "================================"
	echo "Analysis_Folder not found."
	echo ""
	echo "Creating one for you!"
	echo "Please place your folders, with PDF's, in the Analysis_Folder folder."
	echo "Then run this script again."
	exit
fi

}

CheckMainFolderEmpty(){
if [ ! "$(ls -A .)" ]; then
	echo "Jackhammer Text Miner: Analytics"
	echo "================================"
	echo "Analysis_Folder is empty."
	echo ""
	echo "Please place your folders, with PDF's, in the Analysis_Folder folder."
	echo "Then run this script again."
	exit
fi	
}



GetPDFs(){
	Names=(`ls | grep pdf | awk -F . '{print $1}'`) #Find Pdf's; BUG: This will ignore pdf names with multiple dots within its names
	Names2=(`ls | grep txt`)
	Names=( "${Names[@]}" "${Names2[@]}" )
}

GetTXTs(){
	Names2=(`ls | grep txt | awk -F . '{print $1}'`) #Find txt's; BUG: This will ignore pdf names with multiple dots within its names
}

############################################

Because(){
############################################
#Per File File Processsing:
Counter=0
for i in "${Names[@]}"
do
	if $Verbose; then
		echo "Checking file: :"$i
		#echo "Press Enter to Continue..."
		#read Enter
	fi
	#Reset Variables, per file, for each pass:
	SingleFile=$ConvertedDocsPath"/"`date --iso-8601`"_"$i".txt"       # Text Version of the PDF
	SingleFileList=$ConvertedDocsPath"/"`date --iso-8601`"_"$i"_List.txt"        # Spaces converted to Line Returns
	SingleFileList_Unique_Words=$ReportPath_MostWords"/"`date --iso-8601`"_"$i"_List_UniqueWords.txt" # Spaces Converted to Line Returns and Filtered from $Filter1
	SingleFileList_Filtered=$ReportPath_MostWords"/"`date --iso-8601`"_"$i"_List_Filtered_"$Filter1".txt" # Spaces Converted to Line Returns and Filtered from $Filter1
	SingleFileList_Filtered_Summary=$ReportPath_MostWords"/"`date --iso-8601`"_"$i"_List_Filtered_"$Filter1"_Summary.txt" # Spaces Converted to Line Returns and Filtered from $Filter1
	SingleFileList_Filtered_Unique_Words=$ReportPath_MostWords"/"`date --iso-8601`"_"$i"_List_Filtered_"$Filter1"_UniqueWords.txt" # Spaces Converted to Line Returns and Filtered from $Filter1

	PDFInformationReport=$ConvertedDocsPath"/"`date --iso-8601`"_"$i"_Info.txt" # PDF Information saved to file

	if [ ${i: -4} == ".txt" ]; then
		cat $i > $SingleFile
		echo "JUST A TXT FILE" > $$PDFInformationReport
		sha256sum $i | awk '{print "- SHA256 of "$2": "$1}' >> $PDFInformationReport
	else
		#Convert PDF's to Txt:
		pdftotext $i".pdf" $SingleFile
		pdfinfo $i".pdf" > $PDFInformationReport
		sha256sum $i".pdf" | awk '{print "- SHA256 of "$2": "$1}' >> $PDFInformationReport
	fi

	#Convert TxtFiles to single word entries per line:
	cat $SingleFile | tr -c "\11\12\40-\176" "\n" | tr -c [:alnum:] " " | tr " " "\n" | sed '/^$/d' > $SingleFileList #Save to a SingleFileList
	cat $SingleFileList >> $GlobalList # Additionally Save the SingleFileList to the GlobalList

	#MostUsedWords Filtering/Processing:
	cat $SingleFileList | tr '[A-Z]' '[a-z]' | grep -v "0\|1\|2\|3\|4\|5\|6\|7\|8\|9" | tr -d "[\|]\|(\|)\|.\|,\|+\|=\|-\|_\?^??\|?^" | grep -x -v -f ../../include/$Filter1 > $SingleFileList_Filtered
	cat $SingleFileList_Filtered >> $GlobalListFiltered

	cat $SingleFileList_Filtered | sort | uniq -c |  sort -n > $SingleFileList_Filtered_Summary

	cat $SingleFileList_Filtered_Summary | grep -w 1 | awk '{print $2}' > $SingleFileList_Filtered_Unique_Words

	cat $SingleFileList_Filtered_Unique_Words >> $GlobalListFiltered_UniqueWords
#done
#}
#Whaaaaa(){

	#################
	# Top 5 Generation
		SingleFileTop5WordsUsedFiltered=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_Top5_Filtered_"$Filter1".txt"
		tail -n 5 $SingleFileList_Filtered_Summary | sort -nr | awk '{print $2}' > $SingleFileTop5WordsUsedFiltered

		SingleFileTop5Array=(`cat $SingleFileTop5WordsUsedFiltered`)

		echo "This is what was read:"
		Counter2=1
		for j in "${SingleFileTop5Array[@]}"
		do
			echo -e "\tWord "$Counter2": "$j" ["`cat $SingleFileList_Filtered | grep -x "$j" | wc -l`"]"
			SingleFileContextWordListBoth_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_01_Both_Filtered_"$Filter1".txt"
			SingleFileContextWordListBefore_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_02_Before_Filtered_"$Filter1".txt"
			SingleFileContextWordListAfter_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_03_After_Filtered_"$Filter1".txt"

			SingleFileContextWordListBoth_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_01_Both_Filtered_"$Filter1"_Summary.txt"
			SingleFileContextWordListBefore_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_02_Before_Filtered_"$Filter1"_Summary.txt"
			SingleFileContextWordListAfter_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$i"_List_Word_"$Counter2"_"$j"_List_03_After_Filtered_"$Filter1"_Summary.txt"

			cat $SingleFileList_Filtered | grep -B 1 -x "$j" >  $SingleFileContextWordListBoth_Filtered # 1 Word +/- the Word
			cat $SingleFileList_Filtered | grep -A 1 -x "$j" >> $SingleFileContextWordListBoth_Filtered # 1 Word +/- the Word
			cat $SingleFileList_Filtered | grep -B 1 -x "$j" >  $SingleFileContextWordListBefore_Filtered # 1 Word Before
			cat $SingleFileList_Filtered | grep -A 1 -x "$j" >  $SingleFileContextWordListAfter_Filtered # 1 Word After

			cat $SingleFileContextWordListBoth_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$j" > $SingleFileContextWordListBoth_Filtered_Summary
			cat $SingleFileContextWordListBefore_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$j" > $SingleFileContextWordListBefore_Filtered_Summary
			cat $SingleFileContextWordListAfter_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$j" > $SingleFileContextWordListAfter_Filtered_Summary
 			Counter2=$((Counter2+1))
		done
	#################

	Counter=$((Counter+1))
done
############################################

############################################
#Global File Processing:
cat $GlobalListFiltered | sort | uniq -c | sort -n > $GlobalListFiltered_Summary

cat $GlobalListFiltered_UniqueWords > Temp.txt
cat Temp.txt | sort | uniq > $GlobalListFiltered_UniqueWords #Some files MAY have repeated words
rm Temp.txt

############################################

#################
# Top 5 Generation
	GlobalTop5WordsUsedFiltered=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_Top5_Filtered_"$Filter1".txt"
	tail -n 5 $GlobalListFiltered_Summary | sort -nr | awk '{print $2}' > $GlobalTop5WordsUsedFiltered

	Top5Array=(`cat $GlobalTop5WordsUsedFiltered`)

	echo "This is what was Globally read:"
	Counter2=1
	for i in "${Top5Array[@]}"
	do
		echo -e "\tWord "$Counter2": "$i" ["`cat $GlobalListFiltered | grep -x "$i" | wc -l`"]"
		GlobalContextWordListBoth_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_01_Both_Filtered_"$Filter1".txt"
		GlobalContextWordListBefore_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_02_Before_Filtered_"$Filter1".txt"
		GlobalContextWordListAfter_Filtered=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_03_After_Filtered_"$Filter1".txt"

		GlobalContextWordListBoth_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_01_Both_Filtered_"$Filter1"_Summary.txt"
		GlobalContextWordListBefore_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_02_Before_Filtered_"$Filter1"_Summary.txt"
		GlobalContextWordListAfter_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_03_After_Filtered_"$Filter1"_Summary.txt"

		cat $GlobalListFiltered | grep -B 1 -x "$i" >  $GlobalContextWordListBoth_Filtered # 1 Word +/- the Word
		cat $GlobalListFiltered | grep -A 1 -x "$i" >> $GlobalContextWordListBoth_Filtered # 1 Word +/- the Word
		cat $GlobalListFiltered | grep -B 1 -x "$i" >  $GlobalContextWordListBefore_Filtered # 1 Word Before
		cat $GlobalListFiltered | grep -A 1 -x "$i" >  $GlobalContextWordListAfter_Filtered # 1 Word After

		cat $GlobalContextWordListBoth_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$i" > $GlobalContextWordListBoth_Filtered_Summary
		cat $GlobalContextWordListBefore_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$i" > $GlobalContextWordListBefore_Filtered_Summary
		cat $GlobalContextWordListAfter_Filtered | sort | uniq -c | sort -n | grep -v "\-\-" | grep -v "$i" > $GlobalContextWordListAfter_Filtered_Summary
 		Counter2=$((Counter2+1))
	done
#################

############################################
############################################
############################################
############################################
############################################
############################################
############################################
############################################

# Report Generation

############################################
############################################
############################################
############################################
############################################
############################################
############################################
############################################

Finish_time=$(date +%s.%N)
TotalRunTime=$(echo "$Finish_time - $Start_time" | bc)

echo "Processed $Counter Files."
echo "Time duration: $TotalRunTime seconds"
echo "Generating Final Report..."

echo "Jackhammer Text Miner: Analytics" >> $FinalReport
echo "================================" >> $FinalReport
echo "" >> $FinalReport
echo "The following information in this report was generated on: "`date --iso`". From the Jackhammer.sh Script having:" >> $FinalReport
echo "" >> $FinalReport
size=`ls -al | grep Most | grep sh | awk '{print $5}'`
sha256sum ../../Jackhammer.sh | awk '{print "- SHA256: "$1}' >> $FinalReport
echo "- Size of the file in Bytes: "$size >> $FinalReport
echo "" >> $FinalReport

echo "The following report IS NOT guaranteed to be anything other than a tricky way to parse information out of a collection of files." >> $FinalReport
echo "None of the content has been verified by any other means, therefore **USE THE DATA AT YOUR OWN RISK**." >> $FinalReport
echo "If you find that the information is inaccurate, or simply incorrect please let me know." >> $FinalReport
echo "" >> $FinalReport

echo "Global Stats" >> $FinalReport
echo "------------" >> $FinalReport
	echo "" >> $FinalReport
	echo "- Total RunTime: "$TotalRunTime" seconds" >> $FinalReport
	echo "- Total Files Processed: "$Counter >> $FinalReport


	TotPages=`cat $ConvertedDocsPath/*_Info.txt | grep Pages | awk '{sum += $2} END {print sum}'`
	TotWords=`cat $GlobalList | wc -l`
	TotUWords=`cat $GlobalList | sort | uniq -c | wc -l`
	TotSize=`ls -al | grep pdf | awk '{sum += $5} END {print sum}'`
	TotListSize=$(echo "$(ls -al $ConvertedDocsPath | grep "Global" | awk '{print $5}') - $(cat $GlobalList | wc -l)" | bc) #remove each '\n'
	TotListSizeFiltered=$(echo "$(ls -al $ReportPath_MostWords | grep "Global_List" | grep -v Summary | awk '{print $5}')-$(cat $GlobalListFiltered | wc -l)" | bc) #remove each '\n'
	TotFilteredWords=`cat $GlobalListFiltered | wc -l`
#	echo ""
#	echo "THIS IS THE PWD: "`pwd`
#	echo ""
	TotWordsFilter=`cat ../../include/$Filter1 | wc -l`
	TotUWordsFiltered=`cat $GlobalList | grep -x -v -f ../../include/$Filter1 | sort | uniq -c | wc -l`
	TotUWordsNoCase=`cat $GlobalList | tr '[A-Z]' '[a-z]' | tr -d "[\|]\|(\|)\|.\|,\|+\|=\|-\|_\?^??\|?^" | sort | uniq -c | wc -l`
	FilterPercent=`echo "scale=4; "$TotWordsFilter"/"$TotUWordsNoCase"*100" | bc`
	TotUWordsNoCaseFiltered=`cat $GlobalList | tr '[A-Z]' '[a-z]' | tr -d "[\|]\|(\|)\|.\|,\|+\|=\|-\|_\?^??\|?^" | grep -x -v -f ../../include/$Filter1 | sort | uniq -c | wc -l`
	UniqWords=`cat $GlobalListFiltered_UniqueWords | wc -l`

	#$SingleFileList_Filtered_Unique_Words >> $GlobalListFiltered_UniqueWords



	echo "- Total Words: "$TotWords >> $FinalReport
	echo "- Words in Filter: "$TotWordsFilter >> $FinalReport
	echo "- Non-duplicated Words: "$TotUWords >> $FinalReport
	echo "- Total Words when Filtered: "$TotFilteredWords >> $FinalReport
	echo "- Non-duplicated Words when Filtered: "$TotUWordsFiltered >> $FinalReport
	echo "- Percent of Words Filtered (Removed): "`echo "scale=4; 100 - ("$TotFilteredWords"/"$TotWords"*100)" | bc`"%" >>$FinalReport
	echo "- Non-duplicated Words when Case Insensitive: "$TotUWordsNoCase >> $FinalReport
	echo "- Percent of Filter Words within Global Unique Words: "$FilterPercent"%" >> $FinalReport
	echo "- Non-duplicated Words when Case Insensitive, Filtered: "$TotUWordsNoCaseFiltered >> $FinalReport
	#echo "" >> $FinalReport
	echo "- Total Pages: "$TotPages >> $FinalReport
	echo "- Total Words/Page: "`echo "$TotWords/$TotPages" | bc` >> $FinalReport
	echo "- Total Words/Page when Filtered: "`echo "$TotFilteredWords/$TotPages" | bc` >> $FinalReport
	echo "- Total PDF Size: "$TotSize" Bytes, "`echo "$TotSize/1024" | bc`" KiloBytes, "`echo "$TotSize/1024/1024" | bc`" MegaBytes">> $FinalReport
	echo "- Total Word List Size: "$TotListSize" Bytes, "`echo "$TotListSize/1024" | bc`" KiloBytes, "`echo "$TotListSize/1024/1024" | bc`" MegaBytes">> $FinalReport
	echo "- Total Word List Size when Filtered: "$TotListSizeFiltered" Bytes, "`echo "$TotListSizeFiltered/1024" | bc`" KiloBytes, "`echo "$TotListSizeFiltered/1024/1024" | bc`" MegaBytes">> $FinalReport
	echo "- Total List Size/Words: "$(echo "scale=2; $TotListSize/$TotWords"|bc)" Bytes per Word (AKA Letters per Word with ASCII)" >> $FinalReport #, "`echo "$TotSize/1024" | bc`" KiloBytes, "`echo "$TotSize/1024/1024" | bc`" MegaBytes">> $FinalReport
	echo "- Total List Size/Words when Filtered: "$(echo "scale=2; $TotListSizeFiltered/$TotFilteredWords"|bc)" Bytes per Word (AKA Letters per Word with ASCII)" >> $FinalReport #, "`echo "$TotSize/1024" | bc`" KiloBytes, "`echo "$TotSize/1024/1024" | bc`" MegaBytes">> $FinalReport
	#echo "- Total Size/Words when filtered: "`echo "$TotSize/$TotWordsFilter"|bc` >> $FinalReport
	#echo "- Total Images: *TODO*" >> $FinalReport
	#echo "- Total Images/ Total Pages: *TODO*" >> $FinalReport
	echo "- Global Unique Words (words only used once): "$UniqWords >> $FinalReport
	echo "" >> $FinalReport

echo "" >> $FinalReport
echo "\pagebreak" >> $FinalReport
echo "" >> $FinalReport
echo "Top 25 Global Words When Filtered" >> $FinalReport
echo "---------------------------------" >> $FinalReport
echo "" >> $FinalReport
echo "| **Occurrence** | **Word** |" >> $FinalReport
echo "|:-------------:|:--------:|" >> $FinalReport
tail -n 25 $GlobalListFiltered_Summary | sort -nr | awk '{print "| "$1" | "$2" |"}'>> $FinalReport
echo "" >> $FinalReport

echo "" >> $FinalReport
echo "\pagebreak" >> $FinalReport
echo "" >> $FinalReport
Counter2=1
Counter3=0
	for i in "${Top5Array[@]}" #Should still be defined
	do
		GlobalContextWordListBoth_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_01_Both_Filtered_"$Filter1"_Summary.txt"
		GlobalContextWordListBefore_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_02_Before_Filtered_"$Filter1"_Summary.txt"
		GlobalContextWordListAfter_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_Global_List_Word_"$Counter2"_"$i"_List_03_After_Filtered_"$Filter1"_Summary.txt"

		echo "###Top Global Word \""$i"\" ["$Counter2"/5]: Top 10 Context Words - Before and After Breakout" >> $FinalReport
		echo "| **Occurrences** | **Word Before** | **Core Word** | **Word After** | **Occurrences** |" >> $FinalReport
		echo "|:---------------:|:---------------:|:-------------:|:--------------:|:---------------:|" >> $FinalReport
		tail -n 10 $GlobalContextWordListBefore_Filtered_Summary | sort -nr > 1.txt #awk '{print "| "$1" | "$2" |"}' >> $FinalReport

		tail -n 10 $GlobalContextWordListAfter_Filtered_Summary | sort -nr > 3.txt #| awk '{print "| "$1" | "$2" |"}' >> $FinalReport

		echo "||" >2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt
		echo "|**"$i"**|" >> 2.txt #Attempt to place the Core word in the center
		echo "|**("`tail -n 10 $GlobalListFiltered_Summary | grep -w $i | awk '{print $1}'`")**|" >> 2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt
		echo "||" >> 2.txt

		#TODO
		coreWord=`tail -n 10 $GlobalListFiltered_Summary | grep -w $i | awk '{print $1}'`
		#if coreWord/$1.txt[N] >  .25 || coreWord/$3.txt[N] > .25 ==> THEN BIGRAM ASSOCIATION

		paste 1.txt 2.txt 3.txt | awk '{print "|"$1" | "$2" "$3" "$5" | "$4"|"}' >> $FinalReport
		rm 3.txt 2.txt 1.txt #Clean up

		echo "" >> $FinalReport

		echo "###Top Global Word \""$i"\" ["$Counter2"/5]: Top 10 Context Words - Before and After Combined" >> $FinalReport
		echo "| **Occurrences** | **Word** |" >> $FinalReport
		echo "|:----------:|:----:|" >> $FinalReport
			tail -n 10 $GlobalContextWordListBoth_Filtered_Summary | sort -nr | awk '{print "| "$1" | "$2" |"}' >> $FinalReport
		echo "" >> $FinalReport
		echo "\pagebreak" >> $FinalReport
		echo "" >> $FinalReport

 		Counter2=$((Counter2+1))
	done

echo "Generating Per File Breakdown..."

if [[ "${#Names[*]}" > "1" ]]; then #Will only process "Per File" info when there are 2 or more files
	echo "" >> $FinalReport
	echo "\pagebreak" >> $FinalReport
	echo "" >> $FinalReport
	#OneShot=1;

	#echo "Breakout Information Global Stats Quick Sheet" >> $FinalReport
	#echo "=============================================" >> $FinalReport
	for j in "${Names[@]}"
		do
		SingleFileInfo=$ConvertedDocsPath"/"`date --iso-8601`_$j"_Info.txt"
		SingleFileList=$ConvertedDocsPath"/"`date --iso-8601`"_"$j"_List.txt"        # Spaces converted to Line Returns
		SingleFileList_Filtered=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1".txt" # Spaces Converted to Line Returns and Filtered from $Filter1
		SingleFileList_Filtered_Summary=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1"_Summary.txt" # Spaces Converted to Line Returns and Filtered from $Filter1
		SingleFileList_Filtered_Unique_Words=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1"_UniqueWords.txt" # Spaces Converted to Line Returns and Filtered from $Filter1

		TotPages=`cat $SingleFileInfo | grep Pages | awk '{print $2}'`
		TotWords=`cat $SingleFileList | wc -l`
		TotFilteredWords=`cat $SingleFileList_Filtered | sort | uniq | wc -l`
		Percent=`echo "scale=4; 100 - ("$TotFilteredWords"/"$TotWords"*100)" | bc`
		TopWord=`tail -n 1 $SingleFileList_Filtered_Summary | sort -nr | awk '{print $2}'`
		SingleFileSize=`ls -al | grep $j | awk '{print $5}'`
		UniqWords=`cat $SingleFileList_Filtered_Unique_Words | sort | uniq | wc -l`

		echo -e ""$j" "$TotPages" "$TotWords" "$TotFilteredWords" "$Percent" "$TopWord" "$SingleFileSize" "$UniqWords >> $PerFileStats

		#echo -e "- "$j": Pages/Words["$TotPages"/"$TotWords"]; Post Filter["$TotFilteredWords"]; Percent Removed["$Percent"%]; Top Word["$TopWord"]; Single File Size["$SingleFileSize"]; Unique Words["$UniqWords"]" >> $FinalReport
	done

	echo "" >> $FinalReport
	echo "\pagebreak" >> $FinalReport
	echo "" >> $FinalReport

	echo "File Information: Sorted by Most Words" >> $FinalReport
	echo "======================================" >> $FinalReport
	echo "| **File** | **Words** | **Pages** | **Top Word** | **NR, Filtered** | **Unique Words** |" >> $FinalReport
	echo "|:--------:|:---------:|:---------:|:------------:|:----------------:|:----------------:|" >> $FinalReport
	cat $PerFileStats | awk '{print $3" "$1" "$2" "$6" "$4" "$7}' | sort -nr | awk '{print "|"$2" | "$1" | "$3" | "$4" | "$5" | "$6" |"}' >> $FinalReport

	#echo "" >> $FinalReport
	#echo "\pagebreak" >> $FinalReport
	#echo "" >> $FinalReport

	#OneShot=1;
	for j in "${Names[@]}"
		do

		echo -e "\tProcessing file: $j ..."

		#if (( "$OneShot"  != "1" )); then echo "" >> $FinalReport && echo "\pagebreak" >> $FinalReport && echo "" >> $FinalReport; OneShot="2"; fi
		echo "" >> $FinalReport
		echo "\pagebreak" >> $FinalReport
		echo "" >> $FinalReport

		SingleFileInfo=$ConvertedDocsPath"/"`date --iso-8601`_$j"_Info.txt"
		SingleFileList=$ConvertedDocsPath"/"`date --iso-8601`"_"$j"_List.txt"        # Spaces converted to Line Returns
		SingleFileList_Filtered=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1".txt" # Spaces Converted to Line Returns and Filtered from $Filter1
		SingleFileList_Filtered_Summary=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1"_Summary.txt" # Spaces Converted to Line Returns and Filtered from $Filter1
		SingleFileList_Filtered_Unique_Words=$ReportPath_MostWords"/"`date --iso-8601`"_"$j"_List_Filtered_"$Filter1"_UniqueWords.txt" # Spaces Converted to Line Returns and Filtered from $Filter1

		echo "Breakout Information Per File: "$j".pdf" >> $FinalReport
		echo "=============================" >> $FinalReport
		TotPages=`cat $SingleFileInfo | grep Pages | awk '{print $2}'`
		TotWords=`cat $SingleFileList | wc -l`
		UniqWords=`cat $SingleFileList_Filtered_Unique_Words | wc -l`
		echo "- Total Words: "$TotWords >> $FinalReport
		echo "- Total Pages: "$TotPages >> $FinalReport
		TotFilteredWords=`cat $SingleFileList_Filtered | wc -l`
		echo "- Total Words After Filter: "$TotFilteredWords >> $FinalReport
		echo "- Percent of Words Removed: "`echo "scale=4; 100 - ("$TotFilteredWords"/"$TotWords"*100)" | bc`"%" >>$FinalReport
		PDFInformationReport=$ConvertedDocsPath"/"`date --iso-8601`"_"$j"_Info.txt" # PDF Information saved to file
		cat $PDFInformationReport | grep "SHA256" >> $FinalReport
		echo "" >> $FinalReport
		echo "###Top 25 Words" >> $FinalReport
		echo "| **Occurrences** | **Word** |" >> $FinalReport
		echo "|:---------------:|:--------:|" >> $FinalReport
		tail -n 25 $SingleFileList_Filtered_Summary | sort -nr | awk '{print "| "$1" | "$2" |"}' >> $FinalReport
		echo "" >> $FinalReport
		echo "\pagebreak" >> $FinalReport
		echo "" >> $FinalReport

		Counter2=1
		SingleFileTop5WordsUsedFiltered=$ReportPath_ContextWords"/"`date --iso-8601`"_"$j"_Top5_Filtered_"$Filter1".txt"
		SingleFileTop5Array=(`cat $SingleFileTop5WordsUsedFiltered`)

		for i in "${SingleFileTop5Array[@]}" #Should still be defined
			do
			SingleFileContextWordListBoth_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$j"_List_Word_"$Counter2"_"$i"_List_01_Both_Filtered_"$Filter1"_Summary.txt"
			SingleFileContextWordListBefore_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$j"_List_Word_"$Counter2"_"$i"_List_02_Before_Filtered_"$Filter1"_Summary.txt"
			SingleFileContextWordListAfter_Filtered_Summary=$ReportPath_ContextWords"/"`date --iso-8601`"_"$j"_List_Word_"$Counter2"_"$i"_List_03_After_Filtered_"$Filter1"_Summary.txt"

			echo "###Top "$j" Word \""$i"\" ["$Counter2"/5]: Top 10 Context Words - Before and After Breakout" >> $FinalReport
			echo "| **Occurrences** | **Word Before** | **Core Word** | **Word After** | **Occurrences** |" >> $FinalReport
			echo "|:---------------:|:---------------:|:-------------:|:--------------:|:---------------:|" >> $FinalReport
			tail -n 10 $SingleFileContextWordListBefore_Filtered_Summary | sort -nr > 1.txt #awk '{print "| "$1" | "$2" |"}' >> $FinalReport

			tail -n 10 $SingleFileContextWordListAfter_Filtered_Summary | sort -nr > 3.txt #| awk '{print "| "$1" | "$2" |"}' >> $FinalReport

			echo "||" >2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt
			echo "|**"$i"**|" >> 2.txt #Attempt to place the Core word in the center
			echo "|**("`tail -n 10 $SingleFileList_Filtered_Summary | grep -w $i | awk '{print $1}'`")**|" >> 2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt
			echo "||" >> 2.txt

			paste 1.txt 2.txt 3.txt | awk '{print "|"$1" | "$2" "$3" "$5" | "$4"|"}' >> $FinalReport

			rm 3.txt 2.txt 1.txt #Clean up

			echo "" >> $FinalReport

			echo "###Top "$j" Word \""$i"\" ["$Counter2"/5]: Top 10 Context Words - Before and After Combined" >> $FinalReport
			echo "| **Occurrences** | **Word** |" >> $FinalReport
			echo "|:---------------:|:--------:|" >> $FinalReport
			tail -n 10 $SingleFileContextWordListBoth_Filtered_Summary | sort -nr | awk '{print "| "$1" | "$2" |"}' >> $FinalReport
			echo "" >> $FinalReport
			echo "\pagebreak" >> $FinalReport
			echo "" >> $FinalReport

 			Counter2=$((Counter2+1))
		done


	done
fi

echo "" >> $FinalReport
echo "\pagebreak" >> $FinalReport
echo "" >> $FinalReport
echo "Appendix 1: Word Filter \""$Filter1"\"" >> $FinalReport
echo "=======================" >> $FinalReport
echo "- Total Words in Filter:"`cat ../../include/$Filter1 | wc -l` >> $FinalReport
echo "" >> $FinalReport
echo "Word List:" >> $FinalReport
echo "----------" >> $FinalReport
cat -n ../../include/$Filter1 | awk '{print $1". "$2"\n"}' >> $FinalReport

FinalReportSize=`ls -al | grep $FinalReport | awk '{print $5}'`
FinalReportSizeH=`ls -alh | grep $FinalReport | awk '{print $5}'`
echo `date`" Duration: "$TotalRunTime" seconds Size: "$FinalReportSizeH"("$FinalReportSize")" >> $LogFile
############################################


#PDF Generation
echo "Generating PDF($FinalReportPDF) from $FinalReport ..."
pandoc -V linkcolor=black -V geometry:margin=1.125in -f markdown $FinalReport -o $FinalReportPDF
}
