#!/bin/bash

# This script will download all the 17AFIs from the AF website

#Types: D/AF, D/AFI, D/AFPD, AFMAN, AFMD, AFPAM
#Others: AFTO, AFRL, {MAJCOMS}, ANG, {Bases}, HOI, USAFA

declare -A URLFileArray
URLFileArray[0,0]="afi17-101.pdf"
URLFileArray[0,1]="https://static.e-publishing.af.mil/production/1/saf_cn/publication/afi17-101/afi17-101.pdf"
URLFileArray[1,0]="afi17-110.pdf"
URLFileArray[1,1]="https://static.e-publishing.af.mil/production/1/saf_cio_a6/publication/afi17-110/afi17-110.pdf"
URLFileArray[2,0]="afi17-130.pdf"
URLFileArray[2,1]="https://static.e-publishing.af.mil/production/1/saf_cn/publication/afi17-130/afi17-130.pdf"
URLFileArray[3,0]="afi17-140.pdf"
URLFileArray[3,1]="https://static.e-publishing.af.mil/production/1/saf_cio_a6/publication/afi17-140/afi17-140.pdf"
URLFileArray[4,0]="afi17-201.pdf"
URLFileArray[4,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/afi17-201/afi10-1701.pdf"
URLFileArray[5,0]="afi17-203.pdf"
URLFileArray[5,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/afi17-203/afi17-203.pdf"
URLFileArray[6,0]="afi17-210.pdf"
URLFileArray[6,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/afi17-210/afi17-210.pdf"
URLFileArray[7,0]="afi17-213.pdf"
URLFileArray[7,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/afi17-213/afi17-213.pdf"
URLFileArray[8,0]="afi17-221.pdf"
URLFileArray[8,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/afi17-221/afi17-221.pdf"
URLFileArray[9,0]="dafi17-220.pdf"
URLFileArray[9,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/dafi17-220/dafi17-220.pdf"
URLFileArray[10,0]="afpd17-1.pdf"
URLFileArray[10,1]="https://static.e-publishing.af.mil/production/1/saf_cio_a6/publication/afpd17-1/afpd_17-1.pdf"
URLFileArray[11,0]="dafpd17-2.pdf"
URLFileArray[11,1]="https://static.e-publishing.af.mil/production/1/af_a2_6/publication/dafpd17-2/dafpd17-2.pdf"

rows=$((11+1))

echo "There are $rows rows in the array"

for (( i=0; i<$rows; i+=1 )); do
  echo "Looking for: "${URLFileArray[$i,0]}" <"$i",0>"
  if [ ! -f ${URLFileArray[$i,0]} ]; then
    wget -O ${URLFileArray[$i,0]} ${URLFileArray[$i,1]}
  else
    echo "File already exists; skipping!"
  fi
done
