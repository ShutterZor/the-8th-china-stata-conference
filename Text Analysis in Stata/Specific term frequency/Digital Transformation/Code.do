* =============================================================
/* Author Information */
* Name:	        Shutter Zor（左祥太）
* Email:        Shutter_Z@outlook.com
* Affiliation:  Accounting Department, Xiamen University
* Date:         2024/8/1
*				2024/8/21
* Version:      V1.0
*				V1.1
* =============================================================


/* Reference: 

[1]姚加权,冯绪,王赞钧等.语调、情绪及市场影响:基于金融情绪词典[J].管理科学学报,2021,24(05):26-46.
[2]拿铁一定要加冰(左祥太).「Stata」遍历文件夹与批量追加合并[EB/OL].(2023-3-28)[2023-7-24].https://www.bilibili.com/video/BV1ZL411Q7v6.
[3]拿铁一定要加冰(左祥太).「Stata」词频统计下的数字化转型[EB/OL].(2023-6-18)[2023-7-24].https://www.bilibili.com/video/BV1qk4y1M7AM.
[4]OneStata(左祥太).「Stata」词频统计下的数字化转型[EB/OL].(2023-6-18)[2023-7-24].https://mp.weixin.qq.com/s/f3S0uszvDPALtXk425FWBg.

*/



/* Code */
*- 读入文本
local txtFiles : dir "resources/files" files "*.txt"

local N = 1
foreach singleFile in `txtFiles' {

	import delimited "resources/files/`singleFile'"				///
			, delimiter("shutterzor", asstring) 				///
			varnames(nonames) encoding(UTF-8) clear
	
	gen stkcd = ustrregexs(0) if ustrregexm("`singleFile'", "\d+")
	gen year = ustrregexs(0) if ustrregexm("`singleFile'", "_\d+-")
	replace year = substr(year, 2, 4)
	
	tempfile file`N'
	save "`file`N''"
	
	dis as result "file `N' has been finished"
	local N = `N' + 1
}

use "`file1'", clear
local file_total_num = `N' - 1
forvalues fileNum = 2/`file_total_num' {
	append using "`file`fileNum''"
}
rename v1 content
save "MDAText.dta", replace


*- 统计特定词语词频
use MDAText.dta, clear

	*- 数字化转型词汇
	preserve
		import delimited "resources/DigitalWords.txt", encoding(UTF-8) clear
		levelsof v1, local(DigitalWords)
		local totalNum = _N
	restore

	local tempCount = 1
	foreach DigitalWord of local DigitalWords{
		quietly onetext content, k("`DigitalWord'") m(count) g(dw`tempCount')
		local tempCount = `tempCount' + 1
		dis as result %4.2f (`tempCount'-1)/`totalNum'*100
	}
	
		*- 计算数字化转型，并删除无用变量
		egen DT = rowtotal(dw*)
		keep stkcd year content DT
	
	*- 保存结果
	save "result.dta", replace


*- 结果比对
import excel using "企业数字化转型_2007_CNRDS.xlsx", first clear
labone, nrow(1)
drop in 1	
	
destring Fullcount Decount, replace	
bys Scode Year: egen FullDT = sum(Fullcount)
bys Scode Year: egen DeDT = sum(Decount)
duplicates drop Scode Year, force

rename (Scode Year) (stkcd year)
keep stkcd year FullDT DeDT

merge 1:1 stkcd year using result.dta
keep if _merge == 3
drop _merge

kdensity DT, nor scheme(white_tableau)
kdensity FullDT, nor scheme(white_tableau)
kdensity DeDT, nor scheme(white_tableau)



	
	