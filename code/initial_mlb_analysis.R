# This code verifies and explores the data initially scraped from MLB
setwd("/Users/Michael/Coding/Jalgos/MLB")

sink.reset <- function(){
  for(i in seq_len(sink.number())){
    sink(NULL)
  }
}
sink.reset()
sink(file="mlb_analysis.txt", split=TRUE)

library(dplyr)
library(pitchRx)
library(DBI)
library(tidyr)
library(ggplot2)
library(animation)
library(mclust)

mlb_db <- src_sqlite("pitchRx.sqlite3")

# Check dates to ensure all data correctly adjusted. (2014 data was missing previously)
atbats2014 <- filter(tbl(mlb_db, 'atbat'), date >= '2014_01_01')
dates_atbats2014<-count(atbats2014,date)

# Join pitchF/X and atbat data:
pa_full <- left_join(tbl(mlb_db, "pitch"), tbl(mlb_db, "atbat"), 
                     by = c("num", "gameday_link"))
compute(pa_full, name = "pa_full", temporary = FALSE)
pa_full <- tbl(mlb_db, "pa_full") %>% collect()
dim(pa_full)

dbSendQuery(mlb_db$con, 'CREATE INDEX pitch_idx ON pa_full(gameday_link, num)')

pa_full09<- filter(tbl(mlb_db, 'pa_full'), date >= '2009_01_01' & date < '2010_01_01') 
pa_full10<- filter(tbl(mlb_db, 'pa_full'), date >= '2010_01_01' & date < '2011_01_01') 
pa_full11<- filter(tbl(mlb_db, 'pa_full'), date >= '2011_01_01' & date < '2012_01_01') 
pa_full12<- filter(tbl(mlb_db, 'pa_full'), date >= '2012_01_01' & date < '2013_01_01') 
pa_full13<- filter(tbl(mlb_db, 'pa_full'), date >= '2013_01_01' & date < '2014_01_01') 
pa_full14<- filter(tbl(mlb_db, 'pa_full'), date >= '2014_01_01' & date < '2015_01_01') 


k13 <- filter(pa_full13, pitcher_name == 'Clayton Kershaw')
kershaw13<-collect(k13)

b13 <- collect(filter(pa_full13, pitcher_name == 'Mark Buehrle'))
# Take only regular season games:
buehrle13<- subset(b13, b13$date>"2013_04_01")
buehrle13<- buehrle13[,c(1,4,7,8,10:31,34,35,42:46,52:54,57,72,75)]
# Add pitch count:
buehrle13$pitch_nbr <- unlist(sapply(rle(buehrle13$date)$lengths,seq))
# First pass model based clustering:
clust1 <- Mclust(buehrle13[,c(5, 22, 23, 24)])
clust1BIC <- mclustBIC(buehrle13[,c(5, 22, 23, 24)])
pdf("plots/Buerhle13_clust1_BIC.pdf")
plot(clust1BIC)
dev.off()
# Attach cluster membership to data
buehrle13$class1 <- clust1$class
cProb <- data.frame(clust1$z)
buehrle13 <- data.frame(cbind(buehrle13, cProb))
head(buehrle13)

# Plot clusters along variables used in analysis

pdf("plots/Buerhle13_clust1_Proj.pdf", width=20)
par(mfrow=c(1,3))
coordProj(buehrle13[,c(5, 22, 23, 24)], dimens=c(1,3), what="classification", classification=clust1$classification, parameters=clust1$parameters)
coordProj(buehrle13[,c(5, 22, 23, 24)], dimens=c(1,4), what="classification", classification=clust1$classification, parameters=clust1$parameters)
coordProj(buehrle13[,c(5, 22, 23, 24)], dimens=c(3,4), what="classification", classification=clust1$classification, parameters=clust1$parameters)
dev.off()

# Compare to pitch_type as defined by Pitch F/X algorithm
table(buehrle13$class1, buehrle13$pitch_type)

# Look at Pitch F/X pitch type classification confidence 
tapply(buehrle13$type_confidence, buehrle13$pitch_type, mean)


saveHTML(
  animateFX(kershaw13, avg.by = 'pitch_types', layer = list(theme_bw(), facet_grid(.~stand))),
  img.name = "kershaw"
)

prop_na <- function(x) mean(is.na(x))
nas <- pa_full %>% 
  mutate(year = substr(date, 0, 4)) %>%
  group_by(year) %>% 
  summarise_each(funs(prop_na))

na_tidy <- nas %>% 
  tidyr::gather(variable, prop_na, -year) %>%
  # the row_names variable is useless
  filter(variable != "row_names")

# order variables according to the proportion of NAs
na_sort <- na_tidy %>%
  group_by(variable) %>%
  summarise(avg_na = mean(prop_na)) %>%
  arrange(desc(avg_na))

# reorder the variable factor in na_tidy 
na_tidy$variable <- factor(na_tidy$variable, levels = na_sort$variable)
pdf("plots/missing_data.pdf",height=10)
ggplot(data = na_tidy, aes(x = variable, y = prop_na, color = year)) + 
  geom_point(alpha = 0.4) + coord_flip() + xlab("")
dev.off()


# Check NAs for regular season games

game <- tbl(mlb_db, "game") %>%
  mutate(reg = as.integer(game_type == "R")) %>%
  select(gameday_link, reg) %>%
  collect()
# unfortunately we have to prepend "gid_" for this variable
# to match the one in pa_full
game <- game %>%
  mutate(gameday_link = paste0("gid_", gameday_link))
pa_full <- pa_full %>%
  left_join(game, by = "gameday_link")

nas <- mutate(year = substr(date, 0, 4)) %>%
  group_by(year, reg) %>% 
  summarise_each(funs(prop_na))
na_tidy <- tidyr::gather(variable, prop_na, -(year:reg)) %>%
  # the row_names variable is useless
  filter(variable != "row_names")
# order variables according to the proportion of NAs
  summarise(avg_na = mean(prop_na)) %>%
  arrange(desc(avg_na))
# reorder the variable factor in na_tidy 
na_tidy$variable <- factor(na_tidy$variable, levels = na_sort$variable)
pdf("plots/missing_data2.pdf",height=10)
ggplot(data = na_tidy, aes(x = variable, y = prop_na, color = year)) + 
  geom_point(alpha = 0.4) + coord_flip() + xlab("") +
  facet_wrap(~reg)


