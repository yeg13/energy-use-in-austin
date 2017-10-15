
### Dataset for newer audits does not have property ID (cad id) information. I used string merge based on addresses to bring 
### property ID to the dataset with newer audits.

address_cad <- read.csv("C:/Users/guyuye2/Desktop/cad_address.csv")
address <- read.csv("C:/Users/guyuye2/Desktop/address.csv")


names(address_cad)
address_cad$Address_Upper <- as.character(address_cad$Address_upper)
address_cad$Address_Upper <- gsub(" ","", address_cad$Address_Upper)
address_cad$Address_Upper7 <- substr(address_cad$Address_Upper, 1,7)
View(address_cad)
address$Address_Upper <- as.character(address$Address_Upper)
address$Address_Upper <- gsub(" ","", address$Address_Upper)
address$Address_Upper7 <- substr(address$Address_Upper, 1,7)
names(address)
address_merge <- merge(address_cad, address, by = "Address_Upper")
address_merge1 <- merge(address_cad, address, by = "Address_Upper7")
View(address_merge)
View(address_merge1)
address_merge <- address_merge[!(is.na(address_merge$CADID)|address_merge$CADID==""),]
address_merge <- address_merge[!(is.na(address_merge$Address_Upper)|address_merge$Address_Upper==""),]
address_merge1 <- address_merge1[!(is.na(address_merge1$CADID)|address_merge1$CADID==""),]
address_merge1 <- address_merge1[!(is.na(address_merge1$Address_Upper7)|address_merge1$Address_Upper7==""),]

cad_id <- address_merge[, c("CADID", "ID")]
cad_id1 <- address_merge1[, c("CADID", "ID")]


new_form <- read.csv("C:/Users/guyuye2/Desktop/AE/Audit Data/NewForm_ECAD_SF_AuditData_29Sep2015.csv")
new_form <- merge(new_form, cad_id1, by = "ID", all = TRUE)
new_form <- new_form[!grepl("^X.", names(new_form))]
write.csv(new_form, "C:/Users/guyuye2/Desktop/AE/Audit Data/NewForm_ECAD_SF_AuditData_29Sep2015.csv")
