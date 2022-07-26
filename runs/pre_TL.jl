# analysis of SGL Flt1002
cd(@__DIR__)
#cd("D:\\klw\\Research\\Magnetic Navigation\\finalize\\MagNav\\runs")
using Pkg; Pkg.activate("../"); Pkg.instantiate()
using MagNav
using Plots
using HDF5
gr()



# get flight data
data_dir = joinpath(@__DIR__, "..", "data")
#data_dir  = MagNav.data_dir()
#cali_file = string(data_dir,"\\Flt1002-train.h5")
cali_file = joinpath(data_dir,"Flt1002-train.h5")
cali_data  = get_flight_data(cali_file)
#data_file = string(data_dir,"\\Flt1003-train.h5")
data_file = joinpath(data_dir,"Flt1003-train.h5")
xyz_data  = get_flight_data(data_file)

# sensor locations (from front seat rail)
# Mag  1   tail stinger                      X=-12.01   Y= 0      Z=1.37
# Mag  2   front cabin just aft of cockpit   X= -0.60   Y=-0.36   Z=0
# Mag  3   mid cabin next to INS             X= -1.28   Y=-0.36   Z=0
# Mag  4   rear of cabin on floor            X= -3.53   Y= 0      Z=0
# Mag  5   rear of cabin on ceiling          X= -3.79   Y= 0      Z=1.20
# Flux B   tail at base of stinger           X= -8.92   Y= 0      Z=0.96
# Flux C   rear of cabin port side           X= -4.06   Y= 0.42   Z=0
# Flux D   rear of cabin starboard side      X= -4.06   Y=-0.42   Z=0

# create Tolles-Lawson coefficients
cp = Dict()
cp[:pass1] = 0.1  # first  passband frequency [Hz]
cp[:pass2] = 0.9  # second passband frequency [Hz]
cp[:fs]    = 10.0 # sampling frequency [Hz]
i1         = findfirst(cali_data.LINE .== 1002.02)
i2         = findlast( cali_data.LINE .== 1002.02)
#TL_coef_2  = create_TL_coef(cali_data.FLUXB_X[i1:i2],
#                            cali_data.FLUXB_Y[i1:i2],
#                            cali_data.FLUXB_Z[i1:i2],
#                            cali_data.UNCOMPMAG2[i1:i2];cp...)
# data quality of Mag 2 is low. Mag 2 is thus not used during the entire processing.
TL_coef_3  = create_TL_coef(cali_data.FLUXB_X[i1:i2],
                            cali_data.FLUXB_Y[i1:i2],
                            cali_data.FLUXB_Z[i1:i2],
                            cali_data.UNCOMPMAG3[i1:i2];cp...)
TL_coef_4  = create_TL_coef(cali_data.FLUXB_X[i1:i2],
                            cali_data.FLUXB_Y[i1:i2],
                            cali_data.FLUXB_Z[i1:i2],
                            cali_data.UNCOMPMAG4[i1:i2];cp...)
TL_coef_5  = create_TL_coef(cali_data.FLUXB_X[i1:i2],
                            cali_data.FLUXB_Y[i1:i2],
                            cali_data.FLUXB_Z[i1:i2],
                            cali_data.UNCOMPMAG5[i1:i2];cp...)

# create Tolles-Lawson A matrix
A = create_TL_Amat(xyz_data.FLUXB_X,
                   xyz_data.FLUXB_Y,
                   xyz_data.FLUXB_Z)

# correct magnetometer measurements
#mag_2_c = xyz_data.UNCOMPMAG2 - (A*TL_coef_2 .- mean(A*TL_coef_2))
mag_3_c = xyz_data.UNCOMPMAG3 - (A*TL_coef_3 .- mean(A*TL_coef_3))
mag_4_c = xyz_data.UNCOMPMAG4 - (A*TL_coef_4 .- mean(A*TL_coef_4))
mag_5_c = xyz_data.UNCOMPMAG5 - (A*TL_coef_5 .- mean(A*TL_coef_5))

# IGRF offset
calcIGRF = xyz_data.DCMAG1 - xyz_data.IGRFMAG1
mag_3_c = mag_3_c-xyz_data.DIURNAL-calcIGRF
mag_4_c = mag_4_c-xyz_data.DIURNAL-calcIGRF
mag_5_c = mag_5_c-xyz_data.DIURNAL-calcIGRF

#
save_filename = string("data_TL.h5")

h5write(save_filename, "tt",xyz_data.TIME)
h5write(save_filename, "slg",xyz_data.IGRFMAG1)
h5write(save_filename, "mag_3_c",mag_3_c)
h5write(save_filename, "mag_4_c",mag_4_c)
h5write(save_filename, "mag_5_c",mag_5_c)
