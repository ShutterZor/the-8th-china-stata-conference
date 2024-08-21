* =============================================================
/* Author Information */
* Name:	        Shutter Zor（左祥太）
* Email:        Shutter_Z@outlook.com
* Affiliation:  Accounting Department, Xiamen University
* Date:         2024/8/1
* Version:      V1.0
* =============================================================



/* Stata Code for Text Analysis */
*- Reading .txt text
import delimited "assets/HP Full-text.txt", delimiter("shutterzor", asstring) varnames(nonames) encoding("utf-8") clear


*- Converting all letters to lower case
replace v1 = lower(v1)


*- Replacing punctuation marks with spaces
use clear_text_with_punctuations.dta, replace
replace v1 = ustrregexra(v1, "[[:punct:]]", "")
drop if ustrregexm(v1, "^\s+$")			// Deleting empty samples


*- Droping stop words
preserve
	import delimited "assets/EN Stopwords.txt", delimiter("shutterzor", asstring) varnames(nonames) clear
	levelsof v1, local(stopwords)
restore

/*
local text = "he is the apple i want"
foreach word of local text {
	if !strpos(`"`stopwords'"', "`word'") {
		local clear_text = "`clear_text' `word'"
	}
}
dis "`clear_text'"
*/

forvalues index = 1/`=_N' {
	local clear_text = ""
	local text = v1[`index']
	
	foreach word of local text {
		if !strpos(`"`stopwords'"', "`word'") {
			local clear_text = "`clear_text' `word'"
		}
	}
	
	replace v1 = "`clear_text'" in `index'
}

drop if ustrregexm(v1, "^\s+$")			// Deleting empty samples
gen temp = strlen(v1)
drop if temp == 0
drop temp

/*
save clear_text_with_punctuations.dta, replace
*/


/*
*- Replacing meaningless text
gen temp = wordcount(v1)
sum temp, d
drop if temp < 3
drop temp
*/


*- Splitting words and counting the frequency of words
split v1, parse(" ")
drop v1
local Num = 1
foreach variable of varlist _all {
	/*
	   Saving the frequency for each line (text) in a separate temporary file.
	   Such as file1, file2, ..., fileN
	*/
	tempfile file`Num'
	preserve
		keep `variable'
		bys `variable': egen Count = count(`variable') 
		rename `variable' Word
		duplicates drop Word, force
		save "`file`Num''"
	restore
	local Num = `Num' + 1
}

	*- appending these temporary files as one comprehensive file
	clear
	gen Word = ""
	gen Count = .

	local fileNum = `Num' - 1
	forvalues i = 1/`fileNum' {
		append using "`file`i''"
	}
	drop if Word == ""
	bys Word: egen Total = sum(Count)
	duplicates drop Word, force
	keep Word Total
	save "wordCountResult.dta", replace


*- Drawing 1
use wordCountResult.dta, replace
replace Word = ustrregexs(0) if ustrregexm(Word, "[a-z]+")

bys Word: gen new_total = sum(Total)
	
recast str Word	
format %12s Word

sort Word
drop in 1/107
drop in 22218

bys Word: egen max_value = max(new_total)
keep Word max_value
duplicates drop Word, force
sort max_value

sum max_value, d
drop if max_value < 31

wordcloud, n(Word) v(max_value) file("hpfull.html")
	
	
*- Drawing 2
use wordCountResult.dta, replace
replace Word = ustrregexs(0) if ustrregexm(Word, "[a-z]+")

local names "harry hermione dumbledore ron hagrid weasley malfoy sirius voldemort lupin george ginny mcgonagall neville vernon snape dobby quirrel hooch trelawney peter cedric filch moody fudge petunia dudley fang scabbers hedwig"
foreach name of local names {
	replace Word = "`name'" if Word == "`name's"
}

bys Word: gen new_total = sum(Total)
	
recast str Word	
format %12s Word

sort new_total

keep if Word == "harry" | Word == "hermione" | Word == "dumbledore" | Word == "ron" | Word == "hagrid" | Word == "weasley" | Word == "malfoy" | Word == "sirius" | Word == "voldemort" | Word == "lupin" | Word == "george" | Word == "ginny" | Word == "mcgonagall" | Word == "neville" | Word == "vernon" | Word == "snape" | Word == "dobby" | Word == "quirrel" | Word == "hooch" | Word == "trelawney" | Word == "peter" | Word == "cedric" | Word == "filch" | Word == "moody" | Word == "fudge" | Word == "petunia" | Word == "dudley" | Word == "fang" | Word == "scabbers" | Word == "hedwig"	
	
keep Word new_total
bys Word: egen max_value = max(new_total)
keep Word max_value
duplicates drop Word, force
sort max_value

wordcloud, n(Word) v(max_value) file("hp.html")
	
