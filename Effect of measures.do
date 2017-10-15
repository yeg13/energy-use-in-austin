global dirpath "C:\Users\guyuye2\Desktop\AE"
cd $dirpath

**********************************************************************************************************************************
*MERGE EE MEASURES DATA WITH CAD ID'S
*CREATE A CODE FOR EACH MEASURE
**********************************************************************************************************************************

insheet using "$dirpath\EE Measures Data\EEMeasures.csv", clear
save "$dirpath\EE Measures Data\EEMeasures", replace

insheet using "$dirpath\ECAD HH\ECADHH\ECADHH.csv", clear
sort cad_id referencenumber
drop if cad_id==cad_id[_n-1]&programcode==programcode[_n-1]&programyear==programyear[_n-1]&ca==ca[_n-1]

preserve

keep if referencenumber~=""
merge 1:m referencenumber using "$dirpath\EE Measures Data\EEMeasures"
drop if _merge==2
drop _merge
save temp, replace

restore

keep if referencenumber==""
append using temp
erase temp.dta

keep cad_id prem_id programcode programyear ca loanamount referencenumber measurecode mpatticsqft existingrvalue add_rvalue totrvalue

foreach m in AFI AI BDT CDSAI DI DR EA HMM HVACAC HAVACHP PINFO RB SS {
	gen `m' = measurecode=="`m'"
}

gen AEP=programcode=="AEP"
gen AEDW=programcode=="AEDW"
gen HPWES = strmatch(programcode,"HP*")==1

collapse (sum) AFI AI BDT CDSAI DI DR EA HMM HVACAC HAVACHP PINFO RB SS AEP AEDW HPWES ca loanamount, by(cad_id programyear)
drop if programyear==.
ren programyear end_year

replace cad_id = subinstr(cad_id, "R","",1)
destring(cad_id), replace

save "$dirpath\EE Measures Data\EEMeasures_cadid", replace
use "$dirpath\EE Measures Data\EEMeasures_cadid", clear
**********************************************************************************************************************************
*CREATE PROPORTION OF THE MONTH FE
*Convert start and end dates to stata dates
*Keep "normal" length bills
*Create proportion variables
**********************************************************************************************************************************
forval x = 1/4 {
	insheet using "$dirpath\Billing Data\bills_part`x'.txt", clear
	if `x'==4 {
		replace cad_id = subinstr(cad_id, "R","",1)
		destring(cad_id), replace
	}
	if `x'==1 {
		save "$dirpath\Billing Data\bills", replace
	}
	else {
		append using "$dirpath\Billing Data\bills"
		save "$dirpath\Billing Data\bills", replace
	}
}

gen startdate_num = date(begining, "DMY")
gen enddate_num = date(ending, "DMY")
gen duration = enddate-startdate
gen end_day = day(enddate_num)
gen end_month = month(enddate_num)
gen end_year = year(enddate_num)
keep if duration>=27&duration<=35
gen count=0

forval y = 2006/2015 {
replace count=1
forval x = 1/12 {
	if `x'<12 {
		replace count = count+1
	}
	else {
		replace count = 1
	}
	gen FE`x'_`y' = 0
	replace FE`x'_`y' = end_day/duration if end_month==`x'&end_year==`y'
	replace FE`x'_`y' = (duration-end_day)/duration if end_month==count&end_year==`y'&count>1
	replace FE`x'_`y' = (duration-end_day)/duration if end_month==count&end_year==`y'+1&count==1
	replace FE`x'_`y' = 0 if FE`x'_`y'<0
}
}

drop if dkwh~=.
drop dkwh

save "$dirpath\Billing Data\bills", replace

**********************************************************************************************************************************
**********************************************************************************************************************************

use "$dirpath\Billing Data\bills", clear
gen end_year = substr(endingreaddate, -4,.)
destring end_year, replace
merge m:1 cad_id end_year using "$dirpath\EE Measures Data\EEMeasures_cadid"
drop if _merge==2
drop _merge

sort cad_id startdate_num
gen zero_start = (AEP==.&AEP[_n+1]~=.)|(HPWES==.&HPWES[_n+1]~=.)|(AEDW==.&AEDW[_n+1]~=.)&cad_id==cad_id[_n+1]
gen zero_end = (AEP==.&AEP[_n-1]~=.)|(HPWES==.&HPWES[_n-1]~=.)|(AEDW==.&AEDW[_n-1]~=.)&cad_id==cad_id[_n-1]
gen zero = (AEP~=.|HPWES~=.|AEDW~=.)
forval x = 1/12 {
	bysort cad_id: gen pre`x' = zero_start[_n+`x']==1&zero_start==0
	bysort cad_id: gen post`x' = zero_end[_n-`x']==1&zero_end==0
}

sort cad_id startdate_num
foreach x in AFI AI BDT CDSAI DI DR EA HMM HVACAC HAVACHP PINFO RB SS AEP AEDW HPWES ca loanamount {
	bysort cad_id: replace `x'=`x'[_n-1] if `x'==.&_n~=1
	replace `x' = 0 if `x'==.
}

gen AEP_ind = AEP~=0
gen AEDW_ind = AEDW~=0
gen HPWES_ind = HPWES~=0

gen ln_kwh = ln(kwh)

reghdfe kwh FE* AEP_ind AEDW_ind HPWES_ind, absorb(cad_id)
reghdfe ln_kwh FE* AEP_ind AEDW_ind HPWES_ind, absorb(cad_id)
reghdfe ln_kwh FE* AFI AI CDSAI DI DR HVACAC RB SS, absorb(cad_id) vce(cluster cad_id)

replace HPWES_ind = HPWES~=0&(AFI==1|AI==1|CDSAI==1|DI==1|DR==1|HVACAC==1|RB==1|SS==1)




*************************************************************************************************************************************
*GRAPH OF SAVINGS OVER TIME--DOES NOT LOOK GREAT
*************************************************************************************************************************************


*keep if zero==1|pre1==1|pre2==1|pre3==1|pre4==1|pre5==1|pre6==1|pre7==1|pre8==1|pre9==1|pre10==1|pre11==1|pre12==1|post1==1|post2==1|post3==1|post4==1|post5==1|post6==1|post7==1|post8==1|post9==1|post10==1|post11==1|post12==1

reghdfe kwh FE* pre* post*, absorb(cad_id)

gen beta = 0 if zero==1
gen month = 0
forval z = 1/12 {
	replace beta = _b[pre`z'] if pre`z'==1
	replace beta = _b[post`z'] if post`z'==1
	replace month = -1*`z' if pre`z'==1
	replace month = `z' if post`z'==1
}
*save "$dirpath\EE Measures Data\graphic", replace

twoway (scatter beta month)

