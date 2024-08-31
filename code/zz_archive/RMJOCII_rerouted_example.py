#!/home/disk/cig-home/rawrgers/anaconda3/envs/py39/bin/python3

# I had to create a new conda environment to use python 3.9 for some packages I use,
# but I think everything here will work with what's currently in the becassine
# home environment
import os
import xarray as xr
from glob import glob # package to create list of all files in a directory
from pathlib import Path
from tqdm import tqdm

seg_ids = [4719,3059,3062,3063,3045,3071,3102,3103,3115,3117,3116,3089,3351,3353,3363]

# You can also slice the data by the desired hrus (hydrologic resource units). If
# that's something you're needing to do I can create an example of that too!
#       hru_ids = [17010128,
#                 17010129,
#                 17010132,
#                 17010133,
#                 17010130,
#                 17010136,
#                 17010141,
#                 17010143]

# I listed out the models here just in case I needed to redo a loop for just one model.
models = ['inmcm4','MIROC5','IPSL-CM5A-MR','HadGEM2-ES','HadGEM2-CC',
            'GFDL-ESM2M','CanESM2','CSIRO-Mk3-6-0','CNRM-CM5','CCSM4']

# loop through all of the RMJOCII data and pare down stream segments.
# Then save to a new directory.

dir = '/home/disk/becassine/DATA/Model/RMJOCII/REROUTED/nwfsc_data/'

for hydro in ['vic','prms']:
    for model in tqdm(models): # tqdm just keeps track of the for-loop
        for scenario in ['RCP45','RCP85']:
            # designate path
            path = f'{dir}{hydro}/projections/first_route/{model}/{scenario}'

            # open dataset in xarray
            data = xr.open_mfdataset(glob(f'{path}/*.nc'))

            # pare dataset down to desired seg_ids. You can also use the topology files
            # to slice over a lat x lon boundary box to bulk select seg_ids.
            data = data.where(data['reachID'].isin(seg_ids),drop=True)

            # sort seg_ids in ascending order (not necessary)
            data['seg'] = sorted(seg_ids)

            # make new output directory
            Path(f'/home/disk/rocinante/rawrgers/Data/Data_Requests/Rupp/nwfsc_data/{hydro}/projections/first_route/{model}/{scenario}/').mkdir(parents=True, exist_ok=True)

            # save the reachID (i.e., seg_ids) and IRFroutedRunoff (i.e., streamflow) to new netcdf file
            out = data[['reachID','IRFroutedRunoff']].to_netcdf(f'/home/disk/rocinante/rawrgers/Data/Data_Requests/Rupp/nwfsc_data/{hydro}/projections/first_route/{model}/{scenario}/{f}')
