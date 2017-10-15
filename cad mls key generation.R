
## Load required packages
## Set working directory
library(readstata13, lib = "F:\\R packages")
setwd("C:\\Users\\guyuye2\\Desktop\\AE")

ecad_unique <- read.dta13("Crosswalk-TCAD-ECAD-ABOR-DATE.dta")
abor <- read.dta13("F:\\abor_09_28_2016.dta")
audit <- read.csv("Audit Data\\Master_List_SF_ECAD_Audits_5Oct2015.csv")
audit2 <- read.csv("Audit Data\\OldForm_HVAC_SF_ECAD_AuditData.csv")
audit3 <- read.csv("Audit Data\\OldForm_House_SF_ECAD_AuditData_Clean.csv")
hpwes <- read.csv("ECAD HH\\ECADHH.csv")
audit4 <- read.csv("Audit Data\\NewForm_ECAD_SF_AuditData_29Sep2015.csv")
bills <- read.dta13("Billing Data\\bills_all.dta")

## Generate random numbers for MLS
mls <- as.data.frame(matrix(abor[, "mlsnumber"]))
mls <- unique(mls)
nrow(mls) #606591
UID_MLS <- matrix(seq(1, 606591, by = 1), nrow = 606591, ncol = 1)
UID_MLS <- sample(UID_MLS)
abor <- cbind(abor, UID_MLS)
abor[duplicated(abor),] 
abor_code <- abor[, c("UID_MLS", "mlsnumber")]
write.csv(abor_code, "MLS_code.csv")


## Generate random numbers for CADID
cadid1 <- as.data.frame(matrix(ecad_unique[, "CADID"]))
cadid2 <- as.data.frame(matrix(audit[, "CAD.ID"]))
cadid3 <- as.data.frame(matrix(audit2[, "CleanTaxID"]))
cadid4 <- as.data.frame(matrix(audit3[, "CleanTaxID"]))
cadid5 <- as.data.frame(matrix(hpwes[, "CAD_ID"]))
cadid6 <- as.data.frame(matrix(audit4[, "CADID"]))
cadid7 <- as.data.frame(matrix(bills[, "CAD_ID"]))

cadid <- unique(rbind(cadid1, cadid2, cadid3, cadid4, cadid5, cadid6, cadid7))
nrow(cadid) #360673
UID_CAD <- matrix(seq(1, 360673, by = 1), nrow = 360673, ncol = 1)
UID_CAD <- matrix(sample(UID_CAD))
UID_CAD <- cbind(cadid, UID_CAD)
names(UID_CAD)[1] <- "CADID"

write.csv(UID_CAD, "CADID_code.csv")



