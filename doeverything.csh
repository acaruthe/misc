#!/bin/csh

####################
#
# This script does everything to run the WRF.
# 
# Before running, edit the files in the disclaimer below,
# and set the variable foldername to be explicit for the
# case, in YYYYMMDD form, where DD is the starting date
# for the event.
#
####################


#echo 'Before we begin, confirm that:'

#echo '1) We edited download_grb.csh AND download_pgb.csh so that we are downloading the right data.'
#echo '2) We edited namelist_NNRPSFC.wps AND namelist_NNRP.wps to make sure the start date and end date are correct.'
#echo '3) We edited namelist.input to make sure the start date, end date, and run hours are correct.'

#echo 'If so, type "Y" to continue'

#if ($< == 'Y') then


  set iyear = '2002'
  set imonth = '10'
  set iday = '17'
  set inithour = '12'
  set emonth = '10'
  set eday = '24'
  set ehour = '12'
  set rhours = '168'

#http://rda.ucar.edu/datasets/ds090.0/index.html#sfol-wl-/data/ds090.0?g=8
#username: ryan.connelly@valpo.edu password: valpoNWP1
#23841 (2010)
  set pgbchar = 'A21845'
#  set pgbendchar = '1730'
#http://rda.ucar.edu/datasets/ds090.0/index.html#sfol-wl-/data/ds090.0?g=11
  set grbchar = 'A21848'


  set itime = ${iyear}-${imonth}-${iday}_{$inithour}:00:00
  set etime = ${iyear}-${emonth}-${eday}_{$ehour}:00:00

  ./mkwpsnamelists.csh ${itime} ${etime}
  ./mkwrfname.csh ${iyear} ${imonth} ${iday} ${inithour} ${rhours} ${emonth} ${eday} ${ehour}

  cd WRF/DATA/NNRP
  mkdir ${iyear} ; cd ${iyear} ; mkdir SFCNNRP ;  mkdir pgb ; cd ..


  ./dgrb.csh valpoNWP1 ${iyear} ${imonth} ${grbchar}
  set grb = `ls -rc *.grb2d | tail -1f`
  echo ${grb} 
  tar -xvf ${grb}

  ./dpgb.csh valpoNWP1 ${iyear} ${imonth} ${pgbchar}
  set pgb = `ls -rc *.pgb.f00| tail -1f`
  echo ${pgb} 
  tar -xvf ${pgb}
###########

  mv grb* ./${iyear}/SFCNNRP/.

  mv pgb* ./${iyear}/pgb/.

  cd /home/LES/WRF/WPS

# Clean up files from previous run to maintain space.

  rm GRIBFILE.*

  rm met_em.d0*

  rm NNRP:*

  rm NNRPSFC:*

# Now back to our current run.

  ./link_grib.csh /home/LES/WRF/DATA/NNRP/${iyear}/SFCNNRP/

# We think Gobi put this here.  /home/LES/WRF/WPS/link_grib.csh /home/LES/WRF/DATA/NNRP/${foldername}/SFCNNRP/

  cp namelist_NNRPSFC.wps namelist.wps

  ./ungrib.exe >& ungrib_sfcdata.log

  rm namelist.wps
  rm GRIBFILE*
  ./link_grib.csh /home/LES/WRF/DATA/NNRP/${iyear}/pgb/

#  We think Gobi put this here.  /home/LES/WRF/WPS/link_grib.csh /home/LES/WRF/DATA/NNRP/${foldername}/pgb/

  cp namelist_NNRP.wps namelist.wps

  ./ungrib.exe >& ungrib_data.log

  ./geogrid.exe

  ./metgrid.exe

  cd

  cd WRF/WRFV3/test/em_real

# Again, clean up some files from the previous run.

  rm met_em.d0*

  rm wrfrst_*

# And back to our current run.

  cp -sf ../../../WPS/met_em.d0* .

  ./real.exe
  echo "Starting wrf...don't expect to see anything here for a while. Hopefully you ran this script with an & at the end!"
  ./wrf.exe #>& wrf_${iyear}${imonth}${iday}_error.log  

  mv wrfout_d01_${iyear}-${imonth}-${iday}_${inithour}:00:00 /data/LES_cases/October/. 
  mv wrfout_d02_${iyear}-${imonth}-${iday}_${inithour}:00:00 /data/LES_cases/October/. 
  mv wrfout_d03_${iyear}-${imonth}-${iday}_${inithour}:00:00 /data/LES_cases/October/. 

  echo "Making NCL Sutff (hopefully)"
  cd /home/LES/NCL/bin/
  mkdir ${iyear}-${imonth}-${iday}

  ncl wrf_dbz.ncl 'a=addfile("/data/LES_cases/October/wrfout_d03_'${iyear}'-'${imonth}'-'${iday}'_'${inithour}':00:00.nc", "r")' 
  cp dbz.pdf ${iyear}-${imonth}-${iday}/.
#  mv dbz.pdf /data/LES_cases/dbz${iyear}${imonth}${iday}.pdf
  cp plt_SkewTVPZ.pdf ${iyear}-${imonth}-${iday}/skewT_VPZ.pdf
#  mv plt_SkewTVPZ.pdf /data/LES_cases/vpzskew${iyear}${imonth}${iday}.pdf
  ncl wrf_qpf_snow.ncl 'a=addfile("/data/LES_cases/October/wrfout_d03_'${iyear}'-'${imonth}'-'${iday}'_'${inithour}':00:00.nc", "r")'
  cp snownc.pdf ${iyear}-${imonth}-${iday}/snow_liquid_equiv.pdf
#  scp -r ${iyear}-${imonth}-${iday} mwilso14@fujita.valpo.edu:/data/archive2/data_LES/LES_cases/.

  cd /data/LES_cases/October/

  mkdir ${iyear}-${imonth}-${iday}

  cp /home/LES/NCL/bin/dbz.pdf /data/LES_cases/October/${iyear}-${imonth}-${iday}/.
  cp /home/LES/NCL/bin/plt_SkewTVPZ.pdf /data/LES_cases/October/${iyear}-${imonth}-${iday}/skewT_VPZ.pdf
  cp /home/LES/NCL/bin/snownc.pdf /data/LES_cases/October/${iyear}-${imonth}-${iday}/snow_liquid_equiv.pdf

  cd /home/LES/NCL/bin/${iyear}-${imonth}-${iday}/
  rm *
  cd ..
  rmdir ${iyear}-${imonth}-${iday}
  echo "NCL plots transferred over to fujita."



#endif
#!/bin/csh
