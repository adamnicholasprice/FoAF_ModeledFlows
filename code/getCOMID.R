#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Get COMID
#Date: 2023-04-24
#Coder: Adam Price (adnprice@ucsc.edu)
#Purpose: Extract COMID ID's for drying regime gages in PNW.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


library(dataRetrieval)
library(tidyverse)
library(dplyr)

ap_NLDI <- function(x){
  as.integer(dataRetrieval::findNLDI(nwis=x)$origin$comid)
}

gage = 13311000
  
ap_NLDI(gage)


13311250
13311450