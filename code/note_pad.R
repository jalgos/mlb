date_count<-count(atbat,date)
View(date_count)   # Note only first 1000 observations displayed
atbats1 <- filter(tbl(mlb_db, 'atbat'), date < '2012_01_01') 
atbats2 <- filter(tbl(mlb_db, 'atbat'), date >= '2012_01_01')
atbats2014 <- filter(tbl(mlb_db, 'atbat'), date >= '2014_01_01')
dates_atbats1<-count(atbats1,date)
dates_atbats2<-count(atbats2,date)
_
atbats2013 <- filter(tbl(mlb_db, 'atbat'), date >= '2013_01_01')
dates_atbats2013<-count(atbats2013,date)
head(atbats2013)
tail(atbats2013)

> obs<-lapply(lapply(atbat_export.csv,read.csv),nrow)

Reduce("+",obs)
dbDisconnect(mlb_db$con)

table_string<-deparse(substitute(mlb_table))

target_tables_sql<-replace(target_tables_sql,1:length(target_tables_sql),src_tbls(mlb_db)[target_tables_sql])


exists("unamedobject")

target_tables<-sub("(.*?)_.*", "\\1", target_tables)

if(table_export_string%in%src_tbls(mlb_db))
