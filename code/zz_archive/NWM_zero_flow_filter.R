#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: NWM Data Zero Flow Filter Demo
#Date: 5/23/2023
#Coder: Nate Jones (cnjones7@ua.edu)
#Purpose: Faffing about with defining zero flow in NWM model otuput
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

#download model output from gage of interest
df <- read_csv("data//nwm.csv") %>% 
  filter(gage == "14015000") %>% 
  select(
    date, 
    Q_nwm = nwm_flow
  )

#download nwis data and add to df
df <- readNWISdv(siteNumbers = "14015000", parameterCd = '00060') %>% 
  select(
    date = Date, 
    Q_nwis = X_00060_00003) %>% 
  mutate(
    date = ymd(date),
    Q_nwis = Q_nwis*0.0283168
  ) %>% 
  left_join(df,.)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Filter for zero flows -------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Filter A: Round to 0.1 cms
df %>% 
  mutate(Q


