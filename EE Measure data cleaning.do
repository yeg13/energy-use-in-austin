import delimited "C:\Users\guyuye2\Desktop\EE Measures Data\EEMeasures.csv", clear 
save "C:\Users\guyuye2\Desktop\AE\EE Measures Data\EEMeasures.dta"
import excel "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_match.xlsx", sheet("ECADHH") firstrow case(lower) clear
drop if missing(referencenumber)
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_match.dta", replace


use "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_match.dta", clear
drop if missing(cad_id)
sort(cad_id)
drop ca loanamount
#drop dup
duplicates tag (referencenumber), gen(dup)
sort dup referencenumber
tab dup
drop if dup>1
drop audit_address premise_address
duplicates drop
duplicates tag (referencenumber), gen(dup1)
tab dup1
merge 1:m referencenumber using "C:\Users\guyuye2\Desktop\AE\EE Measures Data\EEMeasures.dta"
keep if _merge==3

##Air Flow Improvement
gen AFI=1 if measurecode=="AFI"
replace AFI=0 if missing(AFI)
gen AFI_q = actualquantity if AFI==1
replace AFI_q=0 if missing(AFI_q)

##Air Infiltration
##Variables to look at: (mpatticsqft), existingrvalue add_rvalue totrvalue
gen AI=1 if measurecode=="AI"
replace AI=0 if missing(AI)

##Blower Door Testing
gen BDT=1 if measurecode=="BDT"
replace BDT=0 if missing(BDT)

##Comprehensive Duct Seal and Air Infiltration reduction
gen CDSAI=1 if measurecode=="CDSAI"
replace CDSAI=0 if missing(CDSAI)
gen CDSAI_q = actualquantity if CDSAI==1
replace CDSAI_q=0 if missing(CDSAI_q)

##Duct Insulation
gen DI=1 if measurecode=="DI"
replace DI=0 if missing(DI)
gen DI_q = actualquantity if DI==1
replace DI_q=0 if missing(DI_q)

##Duct Replacement
gen DR=1 if measurecode=="DR"
replace DR=0 if missing(DR)
gen DR_q = actualquantity if DR==1
replace DR_q=0 if missing(DR_q)

##Energy Assessment
gen EA=1 if measurecode=="EA"
replace EA=0 if missing(EA)
gen EA_attic = mpatticsqft if EA==1
replace EA_attic=0 if missing(EA_attic)

##Historical Measure
gen HMM=1 if measurecode=="HMM"
replace HMM=0 if missing(HMM)

##AC Replacement
##look at neweer1
gen HVACAC=1 if measurecode=="HVACAC"
replace HVACAC=0 if missing(HVACAC)

##HP Replacement
##look at neweer1
gen HVACHP=1 if measurecode=="HVACHP"
replace HVACHP=0 if missing(HVACHP)

##Property Information
gen PINFO=1 if measurecode=="PINFO"
replace PINFO=0 if missing(PINFO)

##Radient Barrier
gen RB=1 if measurecode=="RB"
replace RB=0 if missing(RB)
gen RB_q = actualquantity if RB==1
replace RB_q=0 if missing(RB_q)

##Solar Screen
##look at nw, w, sw, s, se, e, ne, totalsqft
gen SS=1 if measurecode=="SS"
replace SS=0 if missing(SS)
gen SS_q = actualquantity if SS==1
replace SS_q=0 if missing(SS_q)

##attic sqft
replace mpatticsqft=0 if mpatticsqft==EA_attic

sort(referencenumber)

keep programyear referencenumber cad_id
duplicates drop
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\Year_ReferenceNo.dta", replace

collapse (sum) nw w sw s se e ne totalsqft mpatticsqft existingrvalue add_rvalue totrvalue neweer1 AFI AFI_q AI BDT CDSAI CDSAI_q DI DI_q DR DR_q EA EA_attic HMM HVACAC HVACHP PINFO RB RB_q SS SS_q, by(referencenumber)
merge 1:1 referencenumber using "C:\Users\guyuye2\Desktop\AE\ECAD HH\Year_ReferenceNo.dta

save "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_All.dta", replace

drop if programyear==2015
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_Old.dta"

#Analysis
use "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_All.dta",clear
sum nw w sw s se e ne totalsqft mpatticsqft existingrvalue add_rvalue totrvalue neweer1 AFI AFI_q AI BDT CDSAI CDSAI_q DI DI_q DR DR_q EA EA_attic HMM HVACAC HVACHP PINFO RB RB_q SS SS_q

tab programyear, sum(add_rvalue)
tab programyear, sum(existingrvalue)

tab programyear DI
tab programyear, sum(DI_q)

tab programyear HVACAC
tab programyear HVACHP

tab programyear SS
tab programyear, sum(SS_q)

import delimited "C:\Users\guyuye2\Desktop\AE\Audit Data\OldForm_House_SF_ECAD_AuditData_Clean.csv", clear 
rename cleantaxid cad_id
drop audit_id
duplicates drop
duplicates tag (cad_id), gen(dup)
sort dup
keep cad_id audityear yearbuilt
save "C:\Users\guyuye2\Desktop\AE\Audit Data\Audit_Year_CAD_Old.dta", replace
duplicates tag (cad_id), gen(dup1)
tab dup1 
gen count=1 if dup1==0
sort dup1 cad_id
egen a=seq() if dup1==1, f(1) t(2) 
egen b=seq() if dup1==2, f(1) t(3)
egen c=seq() if dup1==3, f(1) t(4)
egen d=seq() if dup1==4, f(1) t(5)
egen e=seq() if dup1==5, f(1) t(6)
egen f=seq() if dup1==8, f(1) t(9)
egen g=seq() if dup1==9, f(1) t(10)
replace count=a if !missing(a)
replace count=b if !missing(b)
replace count=c if !missing(c)
replace count=d if !missing(d)
replace count=e if !missing(e)
replace count=f if !missing(f)
replace count=g if !missing(g)
drop a b c d e f g dup1 yearbuilt

help reshape
replace audityear=0 if missing(audityear)
reshape wide audityear, i(cad_id) j(count) 
replace audityear2=. if audityear1==audityear2
replace audityear3=. if audityear1==audityear3|audityear2==audityear3
replace audityear4=. if audityear1==audityear4|audityear2==audityear4|audityear3==audityear4
sum audityear1 audityear2 audityear3 audityear4 
drop audityear4
replace audityear5=. if audityear1==audityear5|audityear2==audityear5|audityear3==audityear5
tab audityear5
replace audityear6=. if audityear1==audityear6|audityear2==audityear6|audityear3==audityear6|audityear5==audityear6
tab audityear6
drop audityear6
replace audityear7=. if audityear1==audityear7|audityear2==audityear7|audityear3==audityear7|audityear5==audityear7
tab audityear7
drop audityear7
replace audityear8=. if audityear1==audityear8|audityear2==audityear8|audityear3==audityear8|audityear5==audityear8
tab audityear8
drop audityear8
replace audityear9=. if audityear1==audityear9|audityear2==audityear9|audityear3==audityear9|audityear5==audityear9
tab audityear9
drop audityear9
replace audityear10=. if audityear1==audityear10|audityear2==audityear10|audityear3==audityear10|audityear5==audityear10
tab audityear10
drop audityear10
replace audityear2=audityear3 if (!missing(audityear3)&missing(audityear2))
replace audityear3=. if audityear2==audityear3
tab audityear3
replace audityear3=audityear5 if (!missing(audityear5)&missing(audityear3))
replace audityear5=. if audityear3==audityear5
tab audityear5
drop audityear5
save "C:\Users\guyuye2\Desktop\AE\Audit Data\Audit_Year_CAD_Old.dta", replace
use "C:\Users\guyuye2\Desktop\AE\Audit Data\Audit_Year_CAD_Old.dta", clear
merge 1:m cad_id using "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_Old.dta", generate(_merge1)
keep if _merge1==3|_merge1==2
tab audityear3
drop audityear3
replace audityear1=. if audityear1==0
replace audityear2=. if audityear2==0
gen timing1=max(audityear1, audityear2)-programyear
gen timing2=min(audityear1, audityear2)-programyear
sum timing1 timing2
count if timing1>0
count if timing2>0
tab programyear if timing1<=0
tab programyear if timing1>0
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_Old.dta",replace
keep if programyear>=2008

*******************************************************************************************************
import excel "C:\Users\guyuye2\Desktop\AE\SF_Brett.xlsx", sheet("MASTER") firstrow clear

gen someAction=1 if (WindowsShadeRecd=="Yes"|InsulateActionRecd=="Yes"|WeatherizationDuctworkRecd=="Yes"|HVACimprovementsRecd=="Yes")
tab someAction
keep if !missing(someAction)

replace ConditionedSqFt=0 if missing(ConditionedSqFt)
replace ConditionedSqFt2=0 if missing(ConditionedSqFt2)
replace ConditionedSqFt3=0 if missing(ConditionedSqFt3)
replace ConditionedSqFt4=0 if missing(ConditionedSqFt4)
#drop TotalConditionedSqft
gen TotalConditionedSqft = ConditionedSqFt + ConditionedSqFt2 + ConditionedSqFt3 + ConditionedSqFt4
replace TotalConditionedSqft=. if TotalConditionedSqft==0

keep StreetAddress WindowsShadeRecd InsulateActionRecd WeatherizationDuctworkRecd HVACimprovementsRecd someAction Built Foundation AveDuctLeak TotalConditionedSqft 

save "C:\Users\guyuye2\Desktop\AE\Audit Data\2015 Some Actions.dta", replace


