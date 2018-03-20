#This script shows how to read the data and correct timestamp in R.
#Since India has +5:30 hours of timezone offset so set TZ variable of R environment accordingly as shown below

library(data.table) # fast library than the default one 
library(xts)
Sys.setenv(TZ='Asia/Kolkata')

#read energy data and plot one day power data 
energy_data_path <- "path to folder containing energy data csv files"
meter <- "acad_build_mains.csv"
data <- fread(paste0(energy_data_path, meter))
data$timestamp <- as.POSIXct(data$timestamp, tz = "Asia/Kolkata", origin = "1970-01-01")
data_power_xts <- xts(data$power,data$timestamp) # convert to XTS time indexed object
plot(data_power_xts['2017-04-04'])


#read occupancy data and plot one day data
occupancy_data_path <- "path to CSV file containing occupancy data"
occu_df <- fread(occupancy_data_path)
occu_df$timestamp <- as.POSIXct(occu_df$timestamp, tz = "Asia/Kolkata", origin = "1970-01-01")
occu_xts <- xts(occu_df$occupancy_count, occu_df$timestamp) 
plot(occu_xts['2017-04-04'])