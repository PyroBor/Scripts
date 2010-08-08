#!/bin/bash
# until zanka

###### until zanka ena
# test_subject=0
# until [ $test_subject -gt 10 ]; do
# 	kdialog --yesno "ali dodam eno številko test_subject ki je $test_subject"
# 	if [[ $? == 0 ]] ; then
# 		((test_subject=test_subject+1))
# 	fi
# done
bujenje="no"
# function sleepy () {
# 	cajt=$1
# 	sleep $cajt
# 	bujenje="yes"
# }
function sleepy {
cajt=$1
for i in $(seq $cajt); do
	sleep 1
	echo "ni se cas za bujenje"
 done
}

sleepy 5 
until [[ $bujenje == yes ]]; do
	sleep 1
	echo "ni še čas za bujenje $bujenje "
done