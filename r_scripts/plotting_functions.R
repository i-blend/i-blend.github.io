# this file contains functions which were used to generate plots in the paper
# Ensure that following packages are installed. We may need these in different functions
# Note for myself: All these functions are defined with complete directory paths in file curate_processed_datasets.R of IIIT_Delhi_data_project. 
library(ggplot2)
library(data.table)
library(xts)
library(reshape2)
library(dplyr)
library(RColorBrewer)# to increase no. of colors
library(plotly)
library(fasttime)
Sys.setenv(TZ='Asia/Kolkata')

summarise_missing_data_plot<- function(){
  # this function is used to plot the plot of paper which shows the days on which quater of the data is missing by gaps. This version also shows the transformer data
  # this function requires two CSVs which are generated by function namely "show_data_present_status" Please read instructions provided in the function to generate two files. Once you are done then execute following statements to get plot as shown in the paper
  def_path <- "path to folder containg CSV with power data status of buildings "
  meter <- "data_present_status.csv"
  data <- fread(paste0(def_path,meter)) 
  data$timestamp <- fasttime::fastPOSIXct(data$timestamp)-19800
  temp <- data[data$timestamp <= as.POSIXct("2017-07-07 23:59:59"),]
  temp_xts <- xts(temp[,-1],temp$timestamp)
  #read transformer power data present status
  transformer_data <-  "path to CSV file containing power data status of transformer"
  df_tran <-  fread(transformer_data)
  df_tran_xts <- xts(df_tran[,-1], fasttime::fastPOSIXct(df_tran$timestamp) - 19800)
  colnames(df_tran_xts) <- c("Transformer_1","Transformer_2","Transformer_3")
  # combine status of buildings and transformer
  temp_xts <- cbind(temp_xts,df_tran_xts)
  day_data <- split.xts(temp_xts,f="days",k=1)
  
  sumry_data <- lapply(day_data, function(x) {
    sumry <- apply(x,2,sum)
    sumry <- ifelse(sumry <=1440/4, NA, 1)
    return(xts(data.frame(t(sumry)),as.Date(index(x[1]),tz="Asia/Kolkata")))
  })
  sumry_data_xts <-  do.call(rbind,sumry_data)
  
  # Calculate uptime for each meter
  uptime<- apply(sumry_data_xts,2,sum,na.rm=TRUE)
  # Next line has been counted manually, 1428 represents total no. of days, subtracted numbers from 1428 shows that corresponding meter started or stopped early by the mentioned  no. of days
  divisor  <- c(1428,1428,1428,1428-97,1428,1428,1428,1428-25,1428-45,1428-105,1428-105,1428-105)
  uptime <-round(as.numeric(uptime/divisor)*100,1)
  temp <- data.frame(timestamp=index(sumry_data_xts),coredata(sumry_data_xts))
  mulfactor <- 1:(NCOL(temp)-1)
  for (i in 2:NCOL(temp)) {
    temp[,i] <- temp[,i] * mulfactor[i-1] }
  data_long <- reshape2::melt(temp,id.vars=c("timestamp"))
  names <- colnames(sumry_data_xts)
  g <- ggplot(data_long,aes(timestamp,value,color=variable)) + geom_line()
  g <- g + theme(axis.text = element_text(color="black"),axis.text.y = element_blank(),axis.ticks.y = element_blank(), legend.title = element_blank(), legend.position = "none" )+ labs(x= " ", y="Meter") + scale_x_date(breaks=scales::date_breaks("6 month"),labels = scales::date_format("%b-%Y"))
  g <- g + annotate("text",x=as.Date("2013-08-10"),y=seq(1.3,12.3,1),label=names,hjust=0)
  g <- g + annotate("text",x=as.Date("2017-07-07"),y=seq(1.3,12.3,1),label=uptime)
  g <- g + scale_y_continuous(sec.axis = sec_axis(~./1, name = "Uptime (%)"  ))
  g
  
  # ggsave(filename="data_missing_plot_version_3.pdf",height = 5,width = 10,units = c("in"))
}

plot_facetted_histograms_of_Data<- function(){
  # this function is used to plot histograms of different meters in grid manner.
  
  # REQUIRED FUNCTION
  remove_outliers <- function(x, na.rm = TRUE, ...) {
    # remove outliers from columns and fill with NAs
    # https://stackoverflow.com/a/4788102/3317829
    qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
    H <- 1.5 * IQR(x, na.rm = na.rm)
    y <- x
    y[x < (qnt[1] - H)] <- NA
    y[x > (qnt[2] + H)] <- NA
    y
  }
  # read buildings power data
  def_path <- "path_to_folder_containiong all_buildings_power.csv"
  meter <- "all_buildings_power.csv"
  data <- fread(paste0(def_path,meter)) 
  data$timestamp <- fasttime::fastPOSIXct(data$timestamp)-19800 # assuming human readable timestamp, 19800 meaning +5:30 is subtracted from UTC 
  df_xts <- xts(data[,-1],data$timestamp)
  # read transformer power data
  transformer_data <-  "path to all_transformer_power.csv"
  df_tran <-  fread(transformer_data)
  df_tran_xts <- xts(df_tran[,-1], fasttime::fastPOSIXct(df_tran$timestamp) - 19800)
  colnames(df_tran_xts) <- c("Transformer_1","Transformer_2","Transformer_3")
  # combine buildings and transformer power data
  df_xts <- cbind(df_xts,df_tran_xts)
  df <- data.frame(timestamp=index(df_xts),coredata(df_xts))
  # handle zero readings in Lecture building
  df$Lecture <- ifelse(df$Lecture==0,NA,df$Lecture)
  # remove timestamp column and apply remove_outliers function
  temp2 <- apply(df[,-1],2,remove_outliers)
  data_long <- reshape2::melt(temp2)
  data_long$value <- data_long$value/1000 # converting to killo watts
  data_long <- data_long[,2:3]
  g <- ggplot(data_long,aes(value)) + geom_histogram(binwidth = 1) + facet_wrap(~Var2 ,scales = "free")
  g <- g + labs(x="Power (kW)", y= "Count") + theme(axis.text = element_text(color = "black"),axis.text.y =  element_blank(),axis.title.y=element_blank(),axis.ticks.y = element_blank())
  g
  # ggsave(filename="filename.pdf",height = 8,width = 12,units = c("in"))
}

plot_histograms_hour_wise_data<- function(){
  # this function is used to plot hour-wise consumption of different buildings and supply transformer
  # read power data of buildings
  def_path <- "path_to_folder_containiong all_buildings_power.csv"
  meter <- "all_buildings_power.csv"
  df <- fread(paste0(def_path,meter)) 
  df$timestamp <- fasttime::fastPOSIXct(df$timestamp)-19800
  df_xts <- xts(df[,-1],df$timestamp)
  # read power data of transformers
  transformer_data <-  "path to all_transformer_power.csv"
  df_tran <-  fread(transformer_data)
  df_tran_xts <- xts(df_tran[,-1], fasttime::fastPOSIXct(df_tran$timestamp) - 19800)
  colnames(df_tran_xts) <- c("Transformer_1","Transformer_2","Transformer_3")
  #combine power data of buildings and transformer
  df_xts <- cbind(df_xts,df_tran_xts)
  # select fixed data for plotting
  start_date <- as.POSIXct("2017-01-01")
  end_date <- as.POSIXct("2017-04-30 23:59:59")
  temp <- df_xts[paste0(start_date,"/",end_date)]
  temp <- data.frame(timestamp=index(temp),coredata(temp))
  temp$hour <- lubridate::hour(temp$timestamp)
  tbl <- as_data_frame(temp)
  dat <- tbl %>% group_by(hour) %>% summarise_all(funs(mean(.,na.rm=TRUE))) %>% select(-timestamp)
  dat_long <- reshape2::melt(dat,id.vars="hour")
  g <- ggplot(dat_long,aes(hour,value/1000)) + geom_bar(stat="identity") + facet_wrap(~variable,scales = "free")
  g <- g + labs(x="Day hour", y= "Power(kW)") + theme(axis.text = element_text(color = "black"))
  g
  ggsave(filename="filename.pdf",height = 8,width = 12,units = c("in"))
}

compute_campus_energy <- function(){
  # this scipt is used to plot total consumption of the campus and the average temperature. It takes data from all the three transformers and plots the data.
  library(data.table)
  library(xts)
  library(ggplot2)
  path <- "path to all_transformer_power.csv"
  df <- fread(path,header = TRUE)
  df_xts <- xts(df[,-1],fasttime::fastPOSIXct(df$timestamp)-19800) # subtracting5:30 according to IST
  power_daily <- apply.daily(df_xts,apply,2, 
                             function(x){
                               temp <- ifelse(any(is.na(x)),NA,sum(x))
                               return(temp)
                             })
  # energy = power * time
  # energy = sum(power*1/60)*1/1000 [kWH]
  energy_daily <- power_daily/60000
  temp <- apply(energy_daily,1,sum,na.rm=TRUE) 
  energy_monthly <- apply.monthly(temp, mean, na.rm=TRUE)
  energy_xts <- xts(as.numeric(energy_monthly),as.Date(row.names(energy_monthly) )) 
  plot(energy_xts)
  #weather data
  weather_path <- "path to weather dataset"
  dirs <- list.files(weather_path,recursive = TRUE,include.dirs = TRUE,pattern = "*FULL.csv")
  weather_files <- lapply(dirs, function(x){
    df <- fread(paste0(weather_path,x))
    df_xts <- xts(df[,-1],fasttime::fastPOSIXct(df$timestamp)-19800)
    return(df_xts)
  })
  weather<- do.call(rbind,weather_files)
  weather_month <- apply.monthly(weather,mean)
  index(weather_month) <- as.Date(index(weather_month))
  index(weather_month) <- as.Date(index(weather_month))
  weather_month <- weather_month["2013-11-25/"]
  temp2 <- data.frame(timestamp=index(energy_xts),coredata(energy_xts),coredata(weather_month$TemperatureC))
  colnames(temp2) <- c("timestamp","Energy","Temperature")
  # temp2$timestamp <- temp2$timestamp - 15 # shifting timestamp of mid of month
  #https://rpubs.com/MarkusLoew/226759
  temp3 <- temp2
  temp3$timestamp <- as.yearmon(temp3$timestamp)
  p <- ggplot() 
  p <- p + geom_line(data=temp3,aes(timestamp,y=Temperature*200,linetype="red"),colour="red")
  p <- p + geom_histogram(data=temp3,aes(timestamp,Energy,colour="black"),stat="Identity",bindwidth=10)
  p <- p + scale_x_yearmon(format ="%b-%Y",n=10)
  p <- p + scale_y_continuous(sec.axis = sec_axis(~./200, name = "Temperature"*"("~degree*"C)"  ))
  p <- p + scale_linetype_manual( labels="Temperature", values = "solid") 
  p <- p + labs(y = "Energy (kWh)", x = "") 
  p <- p + scale_colour_manual(name="", labels= "Energy", values = 'black')
  p <- p+  guides(colour = guide_legend(override.aes = list(colour = "black", size = 1), order = 1), linetype = guide_legend(title = NULL, override.aes = list(linetype = "solid", colour = "red", size = 1),order = 2)) 
  p <- p + theme(legend.key = element_rect(fill = "white", colour = NA),legend.spacing = unit(0, "lines"))
  # ggsave(filename="campus_total_energy_and_temperature_2.pdf",height = 4,width = 10,units = c("in"))
}

show_data_present_status <- function(){
  # this function is used to write a CSV which shows on what timings we have logged meter data and the timings when data got missed.
  # create 2 CSVs corresponding to power data present status in buildings and transformers. Accordingly, run all below statements separtely for each of them 
  # These CSVs are finally used by function "summarise_missing_data_plot"
  path <- "path to either all_transformer_power.csv or all_buildings_power.csv"
  df <- fread(path,header = TRUE)
  df_xts <- xts(df[,-1],fasttime::fastPOSIXct(df$timestamp)-19800) # subtracting5:30 according to IST
  data_present_status <- ifelse(is.na(df_xts),0,1)
  df_status <- data.frame(timestamp=index(df_xts),data_present_status)
  # write.csv(df_status,"data_present_status.csv",row.names = FALSE)
}

visualize_data<- function(){
  # this function first formats data for plotting and then calls another fucntion for actual plotting
  folder_path <- "path to file all_buildings_power.csv"
  meter <- "all_buildings_power.csv"
  df <- fread(paste0(folder_path,meter))
  df$timestamp <- as.POSIXct(df$timestamp,origin="1970-01-01",tz="Asia/Kolkata")
  df_xts <- xts(df[,2:NCOL(df)], fasttime::fastPOSIXct(df$timestamp)-19800)
  # select date range
  startdate <- fasttime::fastPOSIXct(paste0("2017-01-01",' ',"00:00:00"))-19800
  enddate <- fasttime::fastPOSIXct(paste0("2017-04-31",' ',"23:59:59"))-19800
  df_sub <- df_xts[paste0(startdate,"/",enddate)]
  # call below function for plotting
  visualize_dataframe_all_columns(df_sub)
}

visualize_dataframe_all_columns <- function(xts_data) {
  # this functions plots input xts_data 
  dframe <- data.frame(timeindex=index(xts_data),coredata(xts_data))
  df_long <- reshape2::melt(dframe,id.vars = "timeindex")
  colourCount = length(unique(df_long$variable))
  getPalette = colorRampPalette(brewer.pal(8, "Dark2"))(colourCount) 
  g <- ggplot(df_long,aes(timeindex,value,col=variable,group=variable))
  g <- g + geom_line() + scale_colour_manual(values=getPalette)
  ggplotly(g)
}

resample_data_minutely <- function(xts_datap,xminutes) {
  #This function downsamples input xts data by xminutes rate
  ds_data <- period.apply(xts_datap,INDEX = endpoints(index(xts_datap)-3600*0.5, on = "minutes", k = xminutes ), FUN= mean) # subtracting half hour to align IST hours
  align_data <- align.time(ds_data,xminutes*60) # aligning to x seconds
  rm(ds_data)
  return(align_data)
}

visualize_data_at_lower_frequency <- function(){
  # this function first selects data chunk as specified by startdate and enddate, then it down samples data by minutes provided by user
  folder_path <- " path to foldr containing data file"
  meter <- "all_buildings_power.csv"
  df <- fread(paste0(folder_path,meter))
  df$timestamp <- as.POSIXct(df$timestamp,origin="1970-01-01",tz="Asia/Kolkata")
  df_xts <- xts(df[,2:NCOL(df)], fasttime::fastPOSIXct(df$timestamp)-19800)
  # select date range
  startdate <- fasttime::fastPOSIXct(paste0("2017-01-01",' ',"00:00:00"))-19800
  enddate <- fasttime::fastPOSIXct(paste0("2017-04-31",' ',"23:59:59"))-19800
  df_sub <- df_xts[paste0(startdate,"/",enddate)]
  # down sample data by calling below function, Second parameter in the functin corresponds to number of minutes
  df_resampled <- resample_data_minutely(df_sub,240)
  visualize_dataframe_all_columns(df_resampled)
}

plot_line_graph_hour_wise_data<- function(){
  # this function is used to plot hour-wise consumption of different buildings and supply transformer
  library(ggplot2)
  library(data.table)
  library(xts)
  library(dplyr)
  def_path <- "/Volumes/MacintoshHD2/Users/haroonr/Detailed_datasets/IIIT_dataset/processed_phase_2/"
  meter <- "all_buildings_power.csv"
  df <- fread(paste0(def_path,meter)) 
  df$timestamp <- fasttime::fastPOSIXct(df$timestamp)-19800
  df_xts <- xts(df[,-1],df$timestamp)
  
  #ARRANGE TRANSFORMER DATA##
  transformer_data <-  "/Volumes/MacintoshHD2/Users/haroonr/Detailed_datasets/IIIT_dataset/supply/processed_phase_2/all_transformer_power.csv"
  df_tran <-  fread(transformer_data)
  df_tran_xts <- xts(df_tran[,-1], fasttime::fastPOSIXct(df_tran$timestamp) - 19800)
  colnames(df_tran_xts) <- c("Transformer_1","Transformer_2","Transformer_3")
  ########
  df_xts_comb <- cbind(df_xts,df_tran_xts)
  # get January data
  start_date <- as.POSIXct("2017-01-01")
  end_date <- as.POSIXct("2017-01-30 23:59:59")
  temp <- df_xts_comb[paste0(start_date,"/",end_date)]
  data_month_1 <- create_data_summary(temp,month="January")
  # get June data
  start_date <- as.POSIXct("2016-08-01")
  end_date <- as.POSIXct("2016-08-30 23:59:59")
  temp <- df_xts_comb[paste0(start_date,"/",end_date)]
  data_month_6 <- create_data_summary(temp,month="August")
  
  comb_data<- rbind(data_month_1,data_month_6)
  
  dat_long <- reshape2::melt(comb_data,id.vars=c("hour","Month"))
  dat_long$Month <- as.factor(dat_long$Month)
  
  g <- ggplot(dat_long,aes(hour,value/1000)) + geom_line(aes(group=Month,colour=Month,linetype=Month),size=0.8) + facet_wrap(~variable,scales = "free")
  g <- g + labs(x="Day hour", y= "Power(kW)") + theme(axis.text = element_text(color = "black"),legend.position = "top")
  g
  #setwd("/Volumes/MacintoshHD2/Users/haroonr/Dropbox/Writings/IIIT_dataset/figures/")
  # 
  # ggsave(filename="day_hour_usage_plot_2_3.pdf",height = 8,width = 11,units = c("in"))
}

create_data_summary <- function(temp,month_numb) {
  # this function is called by plot_line_graph_hour_wise_data and is used to process the data
  temp <- data.frame(timestamp=index(temp),coredata(temp))
  temp$hour <- lubridate::hour(temp$timestamp)
  tbl <- as_data_frame(temp)
  dat <- tbl %>% group_by(hour) %>% summarise_all(funs(mean(.,na.rm=TRUE))) %>% select(-timestamp)
  dat$Month <- month_numb
  return(dat)
}

create_sunrise_sunset_data <- function() {
  # This function is used to create sunrise and sunset timings.
  library(StreamMetabolism)
  # First two parameters refert to latatiude and longitude of the place
  dat <- sunrise.set(28.5463,77.2732, "2013/08/10", timezone="Asia/Kolkata",num.days = 1428)
  dat$sunrise <- as.numeric(dat$sunrise)
  dat$sunset <- as.numeric(dat$sunset)
  dat <- round(dat,0)
  setwd("/Volumes/MacintoshHD2/Users/haroonr/Detailed_datasets/IIIT_dataset/")
  #write.csv(dat,"sunrise_sunset_IIIT_Delhi.csv",row.names = FALSE)
}

resample_occupancy_minutely <- function(xts_datap,xminutes) {
  #This function resamples input xts data to xminutes rate but it computes max as compared to common mean function
  ds_data <- period.apply(xts_datap,INDEX = endpoints(index(xts_datap)-3600*0.5, on = "minutes", k = xminutes ), FUN= max) # subtracting half hour to align IST hours
  align_data <- align.time(ds_data,xminutes*60) # aligning to x seconds
  rm(ds_data)
  return(align_data)
}

plot_power_occupancy_data <- function(){
  #  I use this function to plot power and occupancy of two buildings.
  #  Remember at the time of plotting, the occupancy dataset was 5:30 hours lagging (seems in UTC) so I forced timestamps to correct value.
  library(ggplot2)
  library(data.table)
  library(xts)
  library(dplyr)
  Sys.setenv(TZ='Asia/Kolkata')
  
  # for first building
  def_path <- "path to power dataset"
  meter <- "acad_build_mains.csv"
  data <- fread(paste0(def_path,meter))
  data$timestamp <- as.POSIXct(data$timestamp,tz="Asia/Kolkata",origin = "1970-01-01")
  start_date <- as.POSIXct("2017-04-01")
  end_date <- as.POSIXct("2017-04-05 23:59:59")
  data_sub <- data[data$timestamp >= start_date & data$timestamp <= end_date,]
  data_sub_xts <- xts(data_sub$power,data_sub$timestamp)
  data_sampled <- resample_data_minutely(data_sub_xts,30)
  
  
  occupancy_path <- "path to occupancy dataset CSV file"
  occu_df <- fread(occupancy_path)
  occu_df$timestamp <- as.POSIXct(occu_df$timestamp,tz="Asia/Kolkata",origin = "1970-01-01")
  occu_df$timestamp <- occu_df$timestamp + 19800 # adding 5:30 hours
  occu_sub <- occu_df[occu_df$timestamp >= start_date & occu_df$timestamp <= end_date,]
  occu_xts <- xts(occu_sub$occupancy_count, occu_sub$timestamp) 
  occu_sampled <- resample_occupancy_minutely(occu_xts,30)

  temp <- cbind(data_sampled,occu_sampled)
  temp_df <- fortify(temp)
  colnames(temp_df) <- c("timestamp","power","occupancy")
  p <- ggplot(temp_df,aes(timestamp,power/1000)) + geom_line(aes(colour="Power"))
  p <- p + geom_line(aes(y=occupancy/10,colour="Occupancy"))
  p <- p + scale_y_continuous(sec.axis = sec_axis(~.*10, name = "Occupancy count"))
  p <- p + scale_colour_manual(values = c("blue", "red")) 
  p <- p + labs(y = "Power (kW)", x = "",colour = "") + scale_x_datetime(breaks=scales::date_breaks("1 day"),labels = scales::date_format("%d-%b"))
  p <- p + theme(legend.position = c(0.2,0.9),axis.text.x = element_text(color = "black"))
  p <- p + theme(axis.text.y.right=element_text(colour = "blue"),axis.title.y.right=element_text(colour = "blue"),axis.title.y.left = element_text(colour = "red"),axis.text.y.left = element_text(color = "red"))
  p
  #ggsave("occu_power_acb_1.pdf",height = 2,width = 6,units = c("in"))
  
  
  # Now for another building
  def_path <- "power dataset path1"
  meter <- "girls_hostel_mains.csv"
  data <- fread(paste0(def_path,meter))
  data$timestamp <- as.POSIXct(data$timestamp,tz="Asia/Kolkata",origin = "1970-01-01")
  start_date <- as.POSIXct("2017-04-01")
  end_date <- as.POSIXct("2017-04-05 23:59:59")
  data_sub <- data[data$timestamp >= start_date & data$timestamp <= end_date,]
  data_sub_xts <- xts(data_sub$power,data_sub$timestamp)
  data_sampled <- resample_data_minutely(data_sub_xts,30)

  occupancy_path <- "occupancy file"
  
  occu_df <- fread(occupancy_path)
  occu_df$timestamp <- as.POSIXct(occu_df$timestamp,tz="Asia/Kolkata",origin = "1970-01-01")
  occu_df$timestamp <- occu_df$timestamp + 19800 # adding 5:30 hours
  occu_sub <- occu_df[occu_df$timestamp >= start_date & occu_df$timestamp <= end_date,]
  occu_xts <- xts(occu_sub$occupancy_count, occu_sub$timestamp) 
  occu_sampled <- resample_occupancy_minutely(occu_xts,30)

  temp <- cbind(data_sampled,occu_sampled)
  temp_df <- fortify(temp)
  colnames(temp_df) <- c("timestamp","power","occupancy")
  p <- ggplot(temp_df,aes(timestamp,power/1000)) + geom_line(aes(colour="Power"))
  p <- p + geom_line(aes(y=occupancy/10,colour="Occupancy"))
  p <- p + scale_y_continuous(sec.axis = sec_axis(~.*10, name = "Occupancy count"))
  p <- p + scale_colour_manual(values = c("blue", "red")) 
  p <- p + labs(y = "Power (kW)", x = "",colour = "") + scale_x_datetime(breaks=scales::date_breaks("1 day"),labels = scales::date_format("%d-%b"))
  p <- p + theme(legend.position = c(0.2,0.9),axis.text.x = element_text(color = "black"))
  p <- p + theme(axis.text.y.right=element_text(colour = "blue"),axis.title.y.right=element_text(colour = "blue"),axis.title.y.left = element_text(colour = "red"),axis.text.y.left = element_text(color = "red"))
  p
  #ggsave("occu_power_girls_main_1.pdf",height = 2,width = 6,units = c("in"))
}
