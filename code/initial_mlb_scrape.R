# This code creates the initial SQLite data base containing all MLB data to 17th June 2015 using pitchRx
setwd("/Users/Michael/Coding/Jalgos/MLB")

sink.reset <- function(){
  for(i in seq_len(sink.number())){
    sink(NULL)
  }
}
sink.reset()
sink(file="mlb_scrape.txt", split=TRUE)

library(dplyr)
library(pitchRx)
library(DBI)
#mlb_db <- src_sqlite("pitchRx.sqlite3", create = TRUE)

mlb_db <- src_sqlite("pitchRx.sqlite3")
#scrape(start = "2008-01-01", end = Sys.Date()-2, connect = mlb_db$con)
#update_db(mlb_db$con) # WARNING: seems to corrupt file data when update fails

scrape_fix <- function(database=mlb_db, mlb_table="atbat",sql_export=TRUE,csv_export=TRUE) {  
  
  if( !(mlb_table%in%src_tbls(database))) stop("Specified table not in database")
  if(sql_export==FALSE && csv_export==FALSE) stop("No exported files: no fix needed")
  message("Please wait, files compiling")
  
  # Scrape fails if name/no. of variables changes and exports batch first to seperate table, then .csv  # We ultimately want to merge all these tables and will do it in stages
  table_string<-mlb_table
  table_export_string<-paste(table_string,"export",sep="_")
  # First identify and merge all the .csv files into one table (if they exist)
  if(csv_export==TRUE) {  
    mlb_table_export.csv<-paste(list.files(path=".",pattern=paste(table_export_string,"*",sep="")))
    mlb_table_export.csv_data<-rbind_all(lapply(mlb_table_export.csv,read.csv))
  }
  # Second we create objects for the SQLite export tables (if they exist)
  mlb_table_original<-tbl(mlb_db, table_string) 
  if(sql_export==TRUE) mlb_table_export<-tbl(mlb_db, table_export_string)
  if(sql_export==TRUE && csv_export==TRUE) {
    # Now we have three tables (two sqlite tables and one R data frame), make a list
    mlb_table_data<-list(mlb_table_original,mlb_table_export,mlb_table_export.csv_data)
  }
  if(sql_export==TRUE && csv_export==FALSE) {
    # Now we have two tables (two sqlite tables), make a list
    mlb_table_data<-list(mlb_table_original,mlb_table_export)
  }
  if(sql_export==FALSE && csv_export==TRUE) {
    # Now we have two tables (one sqlite tables, one R dataframe), make a list
    mlb_table_data<-list(mlb_table_original,mlb_table_export.csv_data)
  }
  
  # To merge in SQLite, we will need all the tables to have the same variables.
  # Start by identifying the variables in each of these tables
  mlb_table_data_vars<-lapply(mlb_table_data,colnames)
  
  # We then identify the missing vars (if any) in each scraped table
  mlb_table_data_vars_missing<-lapply(1:length(mlb_table_data_vars), function(n) setdiff(unlist(mlb_table_data_vars[-n]),mlb_table_data_vars[[n]]))
  
  # Now we add the missing variables to each table and compute
  mlb_table_new<-lapply(1:length(mlb_table_data), function(n) mutate_(mlb_table_data[[n]],.dots=as.list(mlb_table_data_vars_missing[[n]])))
  
  # Since dplyr doesn't compute until explicitly told to, we must do so before combining
  # Note compute creates new table, therefore copy only mutated original table
  compute(mlb_table_new[[1]],name=paste(table_string,"new",sep="_"),temporary=FALSE)    
  # Next, insert mutated export table (SQLite) and concatenated .csv files
  lapply(2:length(mlb_table_new), function(n) db_insert_into(con=database$con,table=paste(table_string,"new",sep="_"),values=as.data.frame(mlb_table_new[[n]])))
  
  # Finally, delete original tables, keeping only new one, then rename table_new
  dbRemoveTable(database$con,name=table_string)
  if(sql_export==TRUE) dbRemoveTable(database$con,name=table_export_string)
  dbSendQuery(database$con,paste("ALTER TABLE ", table_string,"_new RENAME to ", table_string,sep=""))
  
  return(database)
}

#Create vector with the tables that we want to fix, according to each scenario

target_tables_sql<-sub("(.*?)_.*", "\\1", grep("_export",src_tbls(mlb_db),value=TRUE))
target_tables_csv<-unique(sub("(.*?)_export-.*", "\\1",list.files(path=".",pattern="*.csv")))
target_tables_both<-intersect(target_tables_sql,target_tables_csv)
target_tables_sql<-setdiff(target_tables_sql,target_tables_both)
target_tables_csv<-setdiff(target_tables_csv,target_tables_both)

#Apply six to each case(both SQLite & csv exports, only csv, etc.)
#Note this will fail if only csv or only sql do not exist
sapply(1:length(target_tables_both),function(n) scrape_fix(mlb_table=target_tables_both[n]))
sapply(1:length(target_tables_csv), function(n) scrape_fix(mlb_table=target_tables_csv[n],sql_export=FALSE))
sapply(1:length(target_tables_sql), function(n) scarpe_fix(mlb_table=target_tables_sql[n]),sql_csv=FALSE)

# Housekeeping, change date as necessary
scrape_export <- list.files(".", pattern="*export*")
if (length(scrape_export)>0) {
  export_dir<-paste("scrape_export","2015-06-17",sep="_")
  dir.create(export_dir)
  for (i in seq(along=scrape_export)){
    file.copy(scrape_export[i],export_dir)
    file.remove(scrape_export[i])
  }
}

savehistory()
