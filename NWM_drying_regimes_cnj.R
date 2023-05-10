#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: NWM Drying Regimes Exploratory Script
#Date: 5/3/2023
#Coder: Nate Jones (cnjones7@ua.edu)
#Purpose: Calculate drying regime metrics for NWM output
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Initial Analysis Steps: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Download NWM and NWIS data
#Step 2: Calculate drying regime metrics
#   Note, we may have to define zero here. 
#Step 3: Compare

#Data sources:
#NWM data at USGS gage locations (https://www.sciencebase.gov/catalog/item/612e264ed34e40dd9c091228)
#Test bed gages from Adam

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Setup workspace -------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear Memory
remove(list=ls())

#open libraries of interest
library(tidyverse)
library(lubridate)
library(ncdf4)
library(nhdplusTools)
library(sf)
library(parallel)
library(dataRetrieval)

#download gage data
gages <- read_csv("data//dryingRegimes_data_RF.csv") %>% select(gage) 

#define period of study
dates <- seq(ymd('1979-10-01'), ymd('2020-09-30'), by = '1 day')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Add COMID to gage info ------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#tidy gages
gages <- gages %>% 
  #Reduce to unique ids
  unique() %>% 
  #Determine number of characters
  mutate(n_char = nchar(gage)) %>% 
  #Fix number of characters if odd
  mutate(gage = as.character(gage)) %>% 
  mutate(gage = if_else(n_char == 7, paste0(0,gage), gage)) %>% 
  mutate(gage = if_else(n_char == 9, paste0(0,gage), gage)) %>% 
  #remove n_char
  select(-n_char)

#Create function to snage reach code
fun <- function(n){
  #Get COMID
  output <- findNLDI(nwis = gages$gage[n]) %>% 
    st_drop_geometry() %>% 
    select(comid, reachcode) %>% 
    mutate(gage = gages$gage[n])
  
  #Export output
  output
}

#Create error catching fun
error_fun <- function(n){
  tryCatch(
    fun(n), 
    error = function(e) tibble(comid = NA, reachcode = NA, gage = gages$gage[n]))
}

#Prep Clusters
n.cores<-detectCores()-1
cl<-makeCluster(n.cores)
clusterEvalQ(cl, {
  library(tidyverse)
  library(dataRetrieval)
  library(sf)
})
clusterExport(cl, c("gages", "fun"))

#Run in parallel
gages<-parLapply(cl,seq(1, nrow(gages)),error_fun)

#Now, bind rows from list output
gages<-gages %>% bind_rows()

#Stop the clusters
stopCluster(cl)

#Export for posterity 
write_csv(gages, "data//gage_comid_reachcode.csv")


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Download NWM data -----------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define comids of interst
comids <- gages$comid

#define inner func
nwm_data <- function(date, comids){

  #Identify web and local directory locations
  date_text<-date %>% format(., "%Y%m%d") %>% paste0(., "1200")
  year_text <- year(date)
  web_text<-paste0("https://noaa-nwm-retrospective-2-1-pds.s3.amazonaws.com/model_output/",
                   year_text, "/",date_text,".CHRTOUT_DOMAIN1.comp")
  dir_text<-paste0("data/",date_text,".CHRTOUT_DOMAIN1.comp")

  #Download flow data from the web
  download.file(web_text, dir_text, method ='libcurl', mode='wb')

  #Open NET cdf
  nc<-nc_open(dir_text)

  #Extrract Streamflow
  df<-tibble(
    reach_id = ncvar_get(nc, "feature_id"), 
    nwm_flow_cms = ncvar_get(nc, "streamflow"))

  #remove file
  nc_close(nc)
  file.remove(dir_text)

  #Filter based on comid
  df<-df %>% 
    filter(reach_id %in% comids) %>% 
    mutate(date=date)

  #Export file
  df

}

#Create error catching fun
error_fun <- function(n){
  tryCatch(
    nwm_data(
      date = dates[n],
      comids = comids), 
    error = function(e) tibble(reach_id  = NA, streamflow_cms =NA, date = dates[n]))
}

#Prep Clusters
n.cores<-detectCores()-1
cl<-makeCluster(n.cores)
clusterEvalQ(cl, {
  library(tidyverse)
  library(lubridate)
  library(ncdf4)
  library(nhdplusTools)
  library(sf)
})
clusterExport(cl, c("nwm_data", "dates", "comids"))

#Run in parallel
nwm<-parLapply(cl,seq(1, length(dates)),error_fun)

#Now, bind rows from list output
nwm<-nwm %>% bind_rows()

#Stop the clusters
stopCluster(cl)

#Add gage info
nwm <- left_join(
  nwm %>% rename(comid = reach_id) %>% mutate(comid = as.character(comid)),
  gages %>% select(gage, comid) 
)

#Export CSV
write.csv(nwm, "data/nwm.csv")

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# #Step 4: Download NWIS data ----------------------------------------------------
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# #Download data
# nwis<-readNWISdv(siteNumbers = gages$gage, 
#                parameterCd = '00060',
#                startDate = '1979-10-01', 
#                endDate = '2020-09-30')
# 
# #Tidy Data
# nwis<-nwis %>% 
#   as_tibble() %>% 
#   select(
#     gage = site_no,
#     date = Date, 
#     flow = X_00060_00003) %>% 
#   mutate(
#     date = ymd(date), 
#     nwis_flow_cms = 0.0283168*flow) %>% 
#   select(gage,date, nwis_flow_cms)
# 
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# #Step 5: Combine data ----------------------------------------------------------
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# df <- left_join(
#   nwm %>% mutate(gage = as.character(gage)),
#   nwis
# )
#   
# #Next steps...create low flow threshold for nwm data, then calc drying metrics