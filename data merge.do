import delimited C:\Users\guyuye2\Desktop\AE\AustinECAD\Crosswalk-TCAD-ECAD-ABOR-9-29-16.csv, case(upper) clear 

keep PROP_ID GEO_ID MLSNUMBER CAD_ID
keep if(!missing(MLSNUMBER)|!missing(CAD_ID))
duplicates tag (PROP_ID), gen(dup)
tab dup

gen Treatment=1 if (!missing(CAD_ID))
gen Control=1 if (!missing(MLSNUMBER)&missing(CAD_ID))
replace Treatment=0 if missing(Treatment)
replace Control=0 if missing(Control)
count if (Treatment==1&Control==0)
count if (Treatment==1&Control==1)
count if (Treatment==0&Control==0)
count if (Treatment==0&Control==1)
drop CAD_ID MLSNUMBER
duplicates drop
duplicates tag (PROP_ID), gen(dup1)
tab dup1

#166,014 observations

save "C:\Users\guyuye2\Desktop\AE\MLS_CAD.dta", replace


****************************************************************************************
# Number of transactions: Treatment vs. Control

import delimited C:\Users\guyuye2\Desktop\AE\AustinECAD\Crosswalk-TCAD-ECAD-ABOR-9-29-16.csv, case(upper) clear 

keep PROP_ID GEO_ID MLSNUMBER CAD_ID
keep if(!missing(MLSNUMBER)|!missing(CAD_ID))
gen Treatment=1 if (!missing(CAD_ID))
gen Control=1 if (!missing(MLSNUMBER)&missing(CAD_ID))
replace Treatment=0 if missing(Treatment)
replace Control=0 if missing(Control)
count if (Treatment==1&Control==0)
count if (Treatment==1&Control==1)
count if (Treatment==0&Control==0)
count if (Treatment==0&Control==1)
duplicates tag (PROP_ID), gen(dup1)
tab dup1 Treatment


****************************************************************************************
# Compliance

use "C:\Users\guyuye2\Desktop\AE\MLS_CAD.dta", clear
drop if Control==1
tab Treatment
## 22,999 observations

import delimited C:\Users\guyuye2\Desktop\AE\AustinECAD\All_Transactions.csv, clear 
tab close_year
destring age, replace ignore(NA)
gen status="required" if (situs_austin=="1"&age>10)
replace status="age exempt" if (situs_austin=="1"&age<=10)
*replace required=0 if missing(required)
tab status close_year
rename prop_id cad_id
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\EE Measures Data\EEMeasures_cadid.dta"
*replace required = 0 if end_year!=.
*replace exempt=1 if (end_year!=.) & (required==1)
*replace exempt=0 if missing(exempt)
replace status="hpwes exempt" if (situs_austin=="1"&end_year!=.)
drop v1
tab status close_year
rename cad_id PROP_ID
merge m:1 PROP_ID using "C:\Users\guyuye2\Desktop\AE\Parcel_in_ECAD.dta", generate(_merge1)
drop if _merge1==2
keep if close_year>=2008
tostring PROP_ID, generate(CADID)
merge m:m CADID using "C:\Users\guyuye2\Desktop\AE\Audit Data\Audit_CAD.dta", generate(_merge2)
drop if _merge2==2
replace status="comply" if !missing(AUDITDATE)
replace status="non-compliance" if missing(status)
replace status="non-compliance" if status=="required"&missing(AUDITDATE)
drop STREETNUM STREET1 STREET2 STREET3 STREET4 STREET5 STREET6 STREET7 STREET8 L M
drop LOTS SITUS BLOCKS CONDOID PARCEL_BLO GRID Multi_PID Survey_Dat duple
tab status close_year
drop v1 _merge _merge1 _merge2
save "C:\Users\guyuye2\Desktop\AE\Audit Data\Compliance.dta"
******************************************************************************************
# Energy use intensity

use "C:\Users\guyuye2\Desktop\AE\Bilo_start==0.dta", clear
collapse (sum) kwh duration, by(cad_id end_year)
gen kwh_day=kwh/duration
graph box kwh_day, over(end_year)
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", replace
import delimited C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-9-29-16.csv, clear 
rename mlsnumber MLSNumber
drop v1
merge m:1 MLSNumber using "C:\Users\guyuye2\Desktop\AE\Travis_Williamson_All.dta", generate(_merge2)
keep prop_id geo_id MLSNumber situs_zip YearBuilt ParcelNumber SqftTotal FoundationDetails
rename prop_id cad_id
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", generate(_merge4)
keep if _merge4==3
gen eui = kwh_day*365/SqftTotal
graph box eui, over(end_year)
sort end_year
by end_year: sum eui
graph bar (mean) eui, over(end_year)
gen FoundationCode="Slab" if (FoundationDetails=="ONSTILTS,SLAB"|FoundationDetails=="PILINGS,SLAB"|FoundationDetails=="SEEAG,SLAB"|FoundationDetails=="SLAB")
replace FoundationCode="Pier" if (FoundationDetails=="PIER"|FoundationDetails=="PIER,PILINGS"|FoundationDetails=="PIER,SEEAG")
replace FoundationCode="SlabPier" if FoundationDetails=="PIER,SLAB"
replace FoundationCode="Others" if missing(FoundationCode)
graph bar (mean)eui, over(FoundationCode) over(end_year)
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", replace
use "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", clear
graph bar (mean) eui, over(YearBuilt)
*keep if end_year==2015
sort end_year
by end_year: sum eui
graph bar (mean) eui, over(FoundationCode) over(YearBuilt) 
********************************************************************************************
# Energy use intensity with seasonality

use "C:\Users\guyuye2\Desktop\AE\Bilo_start==0.dta", clear
*1 as summer and 0 as regular (based on the season breakdown from electric rates)
gen season = 1 if (end_month>=6 &end_month<=9) 
replace season = 0 if (end_month>=10|end_month<=5)
collapse (sum) kwh duration, by(cad_id end_year season)
gen kwh_day=kwh/duration
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity_Season.dta", replace
tostring cad_id, replace
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", generate(_merge1)
keep if _merge1==3
gen eui1 = kwh_day*365/SqftTotal
sort season
graph bar eui1, over(season) over(YearBuilt)
graph box eui, over(season) over(YearBuilt)
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity_Season.dta", replace
export delimited using "C:\Users\guyuye2\Desktop\AE\Energy_intensity_Season.csv", replace
********************************************************************************************
#AEGB vs non-AEGB in energy use intensity
import delimited "C:\Users\guyuye2\Desktop\AE\Bryans dataset_clean.csv"
**this dataset only contains rating info for 2012 and 2013
duplicates drop
tab aegbparticipation
drop if missing(propid)
rename propid cad_id
save "C:\Users\guyuye2\Desktop\AE\AEGB.dta"
use "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", clear
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\AEGB.dta"
drop if _merge==2
graph bar (mean) eui, over(aegbparticipation) 
destring YearBuilt, replace
gen BuiltDecade="Before 1900" if YearBuilt<1900
replace BuiltDecade="1900-1909" if (YearBuilt>=1900 & YearBuilt<1910)
replace BuiltDecade="1910-1919" if (YearBuilt>=1910 & YearBuilt<1920)
replace BuiltDecade="1920-1929" if (YearBuilt>=1920 & YearBuilt<1930)
replace BuiltDecade="1920-1929" if (YearBuilt>=1920 & YearBuilt<1930)
replace BuiltDecade="1930-1939" if (YearBuilt>=1930 & YearBuilt<1940)
replace BuiltDecade="1940-1949" if (YearBuilt>=1940 & YearBuilt<1950)
replace BuiltDecade="1950-1959" if (YearBuilt>=1950 & YearBuilt<1960)
replace BuiltDecade="1960-1969" if (YearBuilt>=1960 & YearBuilt<1970)
replace BuiltDecade="1970-1979" if (YearBuilt>=1970 & YearBuilt<1980)
replace BuiltDecade="1980-1989" if (YearBuilt>=1980 & YearBuilt<1990)
replace BuiltDecade="1990-1999" if (YearBuilt>=1990 & YearBuilt<2000)
replace BuiltDecade="2000-2009" if (YearBuilt>=2000 & YearBuilt<2010)
replace BuiltDecade="After 2010" if (YearBuilt>=2010)
tab BuiltDecade
graph bar eui, over(aegbparticipation) over(BuiltDecade)
drop v15 v16 v17 v18 v19 v20 v21
graph bar eui, over(hpwes) over(BuiltDecade)
export delimited using "C:\Users\guyuye2\Desktop\AE\Energy_intensity_AEGB.csv"

*******************************************************************************************
#Energy use intensity before and after HPWES programs - Transacted Only

use "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", clear
tostring cad_id, replace
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", replace

use "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_All.dta", clear
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\Energy_intensity.dta", generate(_merge2)
drop if _merge2==2
*generate a variable to indicate whether bill was before or after HPWES
drop BeforeHPWES
gen AfterHPWES=end_year-programyear
tab AfterHPWES
twoway (scatter eui AfterHPWES)
sort AfterHPWES
by AfterHPWES: sum eui
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity_HPWES.dta"
*******************************************************************************************
#Age of properties participating in HPWES

use "C:\Users\guyuye2\Desktop\AE\Energy_intensity_HPWES.dta", clear
destring YearBuilt, replace
sort referencenumber
keep referencenumber nw w sw s se e ne totalsqft mpatticsqft existingrvalue add_rvalue totrvalue neweer1 AFI AFI_q AI BDT CDSAI CDSAI_q DI DI_q DR DR_q EA EA_attic HMM HVACAC HVACHP PINFO RB RB_q SS SS_q cad_id programyear YearBuilt
duplicates drop
gen age=programyear-YearBuilt
graph bar age, over(programyear)
sort programyear
by programyear: sum age
save "C:\Users\guyuye2\Desktop\AE\Energy_intensity_HPWES.dta", replace
*********************************************************************************************
#Sales time vs. HPwES time

import delimited C:\Users\guyuye2\Desktop\AE\AustinECAD\Crosswalk-TCAD-ECAD-ABOR-9-29-16.csv, clear 
drop cad_id
drop v1
rename prop_id cad_id
tostring cad_id, replace
merge m:m cad_id using "C:\Users\guyuye2\Desktop\AE\ECAD HH\HP_ECAD_All.dta", generate(_merge2)
drop if _merge2==1
merge m:m PROP_ID using "C:\Users\guyuye2\Desktop\AE\Audit Data\Compliance.dta",generate(_merge3) force
drop if _merge3==1


gen close_year=substr(closedate,-4,.)
destring close_year, replace
gen AfterProgram=close_year-programyear
hist AfterProgram
sort AfterProgram
sum AfterProgram
tab AfterProgram
tab AfterProgram if close_year>=2008
tab AfterProgram if close_year<2008

gen comply=1 if (status=="age exempt"| status=="comply"|status=="hpwes exempt")
replace comply=0 if status=="non-compliance"

****************************************************************************************************
# New Crosswalk
import delimited C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR.csv, clear
keep if propct ==1
tostring prop_id, generate(CADID)
save "C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-unique.dta", replace

import excel "C:\Users\guyuye2\Desktop\AE\Audit Data\Master_List_SF_ECAD_Audits_5Oct2015.xlsx", sheet("Sheet1") firstrow clear
keep CADID AUDITDATE
duplicates tag CADID AUDITDATE, generate(dup)
drop if dup>0
drop if (missing(CADID)|CADID=="0")
merge m:m CADID using "C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-unique.dta",generate(_merge1)
save "C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-DATE.dta", replace
duplicates tag (mlsnumber), gen(dup1)

*****************************************************************************************************
## Anonymize datasets
import delimited C:\Users\guyuye2\Desktop\Code\CADID_code.csv, case(preserve) clear
tostring CADID, replace
save "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", replace
import delimited C:\Users\guyuye2\Desktop\Code\MLS_code.csv, case(preserve) clear
save "C:\Users\guyuye2\Desktop\Code\MLS_code.dta", replace

## Crosswalk with audit date

use "C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-DATE.dta", clear
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta"
drop if _merge==2
keep UID_CAD mlsnumber tcadimplast tcadimpfirst situs_zip situs_city situs_austin propct mlsyrbuilt closedate cad_id AUDITDATE
merge m:1 mlsnumber using "C:\Users\guyuye2\Desktop\Code\MLS_code.dta", generate(_merge2)
drop if _merge2==2
drop v1 mlsnumber cad_id _merge2
order UID_CAD UID_MLS AUDITDATE closedate mlsyrbuilt propct situs_austin situs_city situs_zip tcadimpfirst tcadimplast
save "C:\Users\guyuye2\Desktop\AE\Crosswalk-TCAD-ECAD-ABOR-DATE-CODED.dta", replace

## ABoR pull on 9/28/16
use "F:\abor_09_28_2016.dta"
merge 1:1 mlsnumber using "C:\Users\guyuye2\Desktop\Code\MLS_code.dta", generate(_merge1)
drop mlsnumber address streetdirprefix streetdirsuffix streetname streetnumber streetsuffix unitcount unitnumber longitude latitude postalcodeplus4 parcelnumber mls v1 _merge1
order UID_MLS
save "C:\Users\guyuye2\Desktop\AE\abor_09_28_2016_coded.dta"

## Audit data 
## Old form HVAC
import delimited "C:\Users\guyuye2\Desktop\AE\Audit Data\OldForm_HVAC_SF_ECAD_AuditData.csv", case(preserve) clear
rename CleanTaxID CADID
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1 ==2
drop _merge1 v1 CADID PhysStAddr_shadow FILE_NAME AUDIT_AC_ID AUDIT_ID 
order UID_CAD
save "C:\Users\guyuye2\Desktop\AE\Audit Data\OldForm_HVAC_SF_ECAD_AuditData_Coded.dta", replace

## Old form house SF Audit
import delimited "C:\Users\guyuye2\Desktop\AE\Audit Data\OldForm_House_SF_ECAD_AuditData_Clean.csv", case(preserve) clear
rename CleanTaxID CADID
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1 == 2
drop v1 AUDIT_ID FILE_NAME CleanDateofAudit CADID StreetAddress Auditor Company CertificateNo TaxAssessorPropertyID Owner PhysicalStreetState PhysicalStreetZip PhysicalStreetAddress PhysicalUnit PhysicalStreetCity
order UID_CAD
save "C:\Users\guyuye2\Desktop\AE\Audit Data\OldForm_House_SF_ECAD_AuditData_Coded.dta", replace

## New Audit
import excel "C:\Users\guyuye2\Desktop\AE\Audit Data\NewForm_ECAD_SF_AuditData_29Sep2015.xls", sheet("NewForm_ECAD_SF_AuditData_29Sep") firstrow clear
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1 == 2
drop ID CADID ForResidence ByAuditor OwnersName StreetAddress CityStateZipCode Auditor AuditorPhone AuditCompany StreetNum StreetDir StreetName StreetType Unit v1 _merge1 
order UID_CAD
save "C:\Users\guyuye2\Desktop\AE\Audit Data\NewForm_ECAD_SF_AuditData_29Sep2015_Coded.dta", replace

## ECADHH_match
use "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_match.dta"
rename cad_id CADID
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1 == 2
drop CADID audit_address premise_address prem_id v1 _merge1
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_match_coded.dta", replace

## ECADHH
import delimited "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH.csv", varnames(1) case(preserve) clear
rename CAD_ID CADID
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1 == 2
drop CADID v1 _merge1
save "C:\Users\guyuye2\Desktop\AE\ECAD HH\ECADHH_coded.dta", replace

## Bills
use "C:\Users\guyuye2\Desktop\AE\Billing Data\bills.dta" ,clear

import delimited "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part1.txt", varnames(1) case(preserve) clear
tostring CAD_ID, replace
save "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part1.dta", replace
import delimited "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part2.txt", varnames(1) case(preserve) clear
tostring CAD_ID, replace
save "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part2.dta", replace
import delimited "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part3.txt", varnames(1) case(preserve) clear
tostring CAD_ID, replace
save "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part3.dta", replace
import delimited "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part4.txt", varnames(1) case(preserve) clear
tostring CAD_ID, replace
save "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part4.dta", replace
append using "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part1.dta" "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part2.dta" "C:\Users\guyuye2\Desktop\AE\Billing Data\Bills_part3.dta"
save "C:\Users\guyuye2\Desktop\AE\Billing Data\bills_all.dta" 
rename CAD_ID CADID
merge m:1 CADID using "C:\Users\guyuye2\Desktop\Code\CADID_code.dta", generate(_merge1)
drop if _merge1==2
drop CADID _merge1 v1
save "C:\Users\guyuye2\Desktop\AE\Billing Data\bills_all_coded.dta"



