#!/bin/bash
workdir="/home/bor/tmp/gemrb/gemrb/trunk/gemrb/docs/en/GUIScript"
index_title="GUIScript function docs"
search="See also:"
#za vse txt datoteke
txt_files=$(ls -l $workdir/*.txt)
cd $workdir
for txt_file in *; do
if [[ "${txt_file##*.}" != "txt" ]]; then
	continue
fi
	cp $txt_file ${txt_file%.*}.html
	#vrstica k vsebuje te imena datotek
	the_line=$(grep "$search" "$txt_file"  | head -n 1)
	if [[ $the_line != "" ]]; then
		#zgori če nima nič pol narest nč
		# če je skenslamo nazačetku "see also"
		line=${the_line##*:}
		for want_link in $line; do
		# nekateri want_linki imajo vejico
			#test če html še ne obstaja jo nardimo
			#nardimo link v html file
			if [[ ${want_link##*,} == "" ]]; then
				# v tem primeru ima vejico, zato jo skensslami in nakoncu dodamo tako da ne bo link obsegal vejice
				sed_ukaz="/$search/ s-$want_link-<a href=${want_link//,/}.html>${want_link//,/}\</a>,-g"
			else
				# V kolikor nima vejice nakoncu je stvar dosti bolj enostavna
				sed_ukaz="/$search/ s-$want_link\$-<a href=$want_link.html>$want_link</a>-"
			fi
			[[ -f ${want_link//,/}.txt ]] && sed -i "$sed_ukaz" ${txt_file%.*}.html
		done
	fi
done

for html_file in *; do
if [[ "${html_file##*.}" != "html" ]]; then
	continue
fi
	#delete blank lines
	sed -i "/^ *$/d" $html_file
	#malo break linov
	sed -i "s,$,<br>," $html_file
	#naslov
	sed -i "1 s,^,<h1>${html_file%.*}</h1>," $html_file
	#malo boldanja
	sed -i "s,Description:\|Return value:\|Prototype:\|Parameters:\|See also:\|MD5\|:Example:\|Examples:,<br><b>&</b>," $html_file
	sed -i "$ s,$,<br><a href=index.html>index</a>," $html_file
	sed -i "1 s,^,<html><body>\n," $html_file
	sed -i "$ s,$,\n</body></html>," $html_file
	if [[ ! -f indexX.html ]]; then
		echo "" > indexX.html
	fi
	sed -i "1 s,$,\n<a href=$html_file>${html_file%.*}</a><br>," indexX.html
done
sort -o index.html indexX.html
sed -i "1 s,^,<h1>$index_title</h1>," index.html
sed -i "1 s,^,<html><body>\n," index.html
sed -i "$ s,$,\n</body></html>," index.html
rm indexX.html