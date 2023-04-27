#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Get COMID
#Date: 2023-04-24
#Coder: Adam Price (adnprice@ucsc.edu)
#Purpose: Extract COMID ID's for drying regime gages in PNW.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


library(dataRetrieval)

dat = read.csv('../data/PNW_DryingRegimeGages.csv')

tt = dataRetrieval::findNLDI(nwis=paste0('"',str(dat$gage),'"'))

                             