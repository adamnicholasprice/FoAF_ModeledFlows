#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Get COMID
#Date: 2023-04-24
#Coder: Adam Price (adnprice@ucsc.edu)
#Purpose: Extract COMID ID's for drying regime gages in PNW.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


library(dataRetrieval)
library(tidyverse)
library(dplyr)

dat = read.csv('../data/PNW_DryingRegimeGages.csv')

gageInfo  = dataRetrieval::readNWISsite(dat$gage)

gageInfo <- gageInfo %>%
  select(.,site_no,station_nm,dec_lat_va,dec_long_va)
gageInfo$site_no = as.integer(gageInfo$site_no)


ap_NLDI <- function(x){
  as.integer(dataRetrieval::findNLDI(nwis=x)$origin$comid)
}

gageNHD = tibble(lapply(dat$gage,ap_NLDI)) %>%
  unlist() %>%
  data_frame() %>%
  cbind(.,dat$gage)%>%
  rename_with(.cols=1,~"comid")

colnames(gageNHD) <- c('comid','gage')


pnwNP <- dat %>%
  left_join(x=dat,y=gageNHD, by=join_by(gage))


write.csv(pnwNP,'../data/pnwNP_Info.csv',row.names = F)

### Read in all NP from PNW
dat = read.csv("../data/pnwNWall_DailyStats.csv")
colnames(dat) <- c("gage","numZero","numOne","startDate","endDate")

gageNHD = tibble(lapply(dat$gage,ap_NLDI)) %>%
  unlist() %>%
  data_frame() %>%
  cbind(.,dat$gage)%>%
  rename_with(.cols=1,~"comid")

colnames(gageNHD) <- c('comid','gage')

pnwNP <- dat %>%
  left_join(x=dat,y=gageNHD, by=join_by(gage))

write.csv(pnwNP,'../data/pnwNPall_InfowStats.csv',row.names = F)
