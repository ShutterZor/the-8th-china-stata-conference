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
import delimited "assets/西游记.txt", delimiter("shutterzor", asstring) varnames(nonames) encoding("utf-8") clear


*- Replacing punctuation marks with spaces
replace v1 = ustrregexra(v1, "[[:punct:]]", "")


*- Keep Chinese characters
replace v1 = ustrregexs(0) if ustrregexm(v1, "[\u4e00-\u9fa5]{0,}")
drop if ustrlen(v1) <= 1			// Deleting empty samples or single character


*- Spliting words
gen v2 = ""
forvalues index = 1/`=_N' {
	local wordcount_num = ustrwordcount(v1[`index'], "cn")
	local split_word_text = ""
	forvalues wordnum = 1/`wordcount_num' {
		local split_word_text = "`split_word_text' " + ustrword(v1[`index'], `wordnum', "cn")
	}
	replace v2 = "`split_word_text'" in `index'
}


*- Droping stop words
preserve
	import delimited "assets/CN Stopwords.txt", delimiter("shutterzor", asstring) varnames(nonames) encoding("utf-8")  clear
	levelsof v1, local(stopwords)
restore

forvalues index = 1/`=_N' {
	local clear_text = ""
	local text = v2[`index']
	
	foreach word of local text {
		if !strpos(`"`stopwords'"', "`word'") {
			local clear_text = "`clear_text' `word'"
		}
	}
	
	replace v2 = "`clear_text'" in `index'
}


*- Splitting words and counting the frequency of words
drop v1
rename v2 v1
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


*- Drawing
use wordCountResult.dta, replace
	
recast str Word	
format %12s Word

sort Total

sum Total, d
drop if Total < 13

wordcloud, n(Word) v(Total) file("西游记.html")
	
