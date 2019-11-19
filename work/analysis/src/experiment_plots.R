# svn keywords:
# $Rev: 710 $: Revision of last commit
# $Author: paterno $: Author of last commit
# $Date: 2010-08-26 16:26:58 -0500 (Thu, 26 Aug 2010) $: Date of last commit

# TODO: Figure out how intelligent error handling should be done for a
# command-line-driven R script.

library(methods)
library(DBI)
library(lattice)

get.driver.name <- function(drivername)
{
	# TODO: Introduce real error handling.
	if (drivername == "sqlite") 
	  {
		library(RSQLite)
		"SQLite"
	  }
	else 
	  { 
		library(RMySQL)
		"MySQL"
	  }
}

get.connection <- function(drivername, user, password, host, dbname)
{
	# TODO: Introduce real error handling.	
    m   <- dbDriver(get.driver.name(drivername))
    if (drivername == "sqlite")
      {
	    dbConnect(m, dbname=dbname)
	  }
	else
	  {
		dbConnect(m, user=user, password=password, host=host, dbname=dbname)
	  }
}

load.trials.df <- function(con,expid) {
  query  <- "select wall_clock_time as trial_time,experiment_id,id as trial_id from trials where experiment_id=%d"
  squery <-  sprintf(query, expid)
  df     <- dbGetQuery(con,squery)
  df$experiment_id <- as.factor(df$experiment_id)
  df$trial_id      <- as.factor(df$trial_id)
  df
}

# Query the database attached to the connection con, and
# return all the trials for an experiment
#trials with max number of events

load.metrials.df <- function(con,expid) {
  query="select tr.experiment_id, tr.id as trial_id, exp.max_exp_event_id, max(eru.event) as max_trial_event_id, tr.wall_clock_time as trial_time
         from trials as tr, event_resource_uses as eru, (select tr.experiment_id, max(eru.event) as max_exp_event_id
                                                         from trials as tr, event_resource_uses as eru
                                                         where tr.experiment_id=%d and tr.id=eru.trial_id group by experiment_id) as exp
         where tr.experiment_id=%d and tr.id=eru.trial_id and exp.experiment_id=tr.experiment_id 
         group by tr.experiment_id,trial_id"

  squery<-sprintf(query,expid,expid)
  df <- dbGetQuery(con,squery)
  df$experiment_id <- as.factor(df$experiment_id)
  df$trial_id      <- as.factor(df$trial_id)
  # print("-*-*-*-*-")
  # print(df)
  # print("-*-*-*-*-")
  df
}

total.times.plot <- function(df, expids) {
  bwplot(experiment_id~trial_time|experiment_id, 
         subset(df,experiment_id %in% expids),
         xlab = 'Total time (s)', 
         ylab = 'Experiment ID')
}

total.metimes.plot <- function(df, expids) {
  bwplot(experiment_id~trial_time|experiment_id, 
         subset(df, experiment_id %in% expids & max_exp_event_id==max_trial_event_id),
         xlab = 'Total time for full trials', 
         ylab = 'Experiment ID')
}

generate.png <- function(plot, filename) {
  png(filename,width = 1200, height = 800, units = "px")
  print(plot)
  dev.off()
}

load.meevents.df <- function(con,expid) {
  query <- "select tr.experiment_id, tr.id as trial_id, eru.event as event_id,
                   mee.max_exp_event_id, met.max_trial_event_id, tr.wall_clock_time as trial_time, eru.time as event_time
                   from trials as tr, event_resource_uses as eru,
                  (select tr.experiment_id, max(eru.event) as max_exp_event_id
                   from trials as tr, event_resource_uses as eru
                   where tr.experiment_id=%d and tr.id=eru.trial_id group by experiment_id) as mee,
                   (select tr.id as trial_id, max(eru.event) as max_trial_event_id
                   from trials as tr, event_resource_uses as eru
                   where tr.experiment_id=%d and tr.id=eru.trial_id group by trial_id) as met
                   where tr.experiment_id=%d and tr.id=eru.trial_id and tr.experiment_id=mee.experiment_id and met.trial_id=tr.id
                   group by tr.experiment_id,trial_id,event_id"
  squery<-sprintf(query,expid,expid,expid)
  df <- dbGetQuery(con,squery)
  df$experiment_id <- as.factor(df$experiment_id)
  df$trial_id      <- as.factor(df$trial_id)
  df
}

event.metimes.plot <- function(df, expids) {
  bwplot(event_id~event_time|experiment_id, 
         subset(df, experiment_id %in% expids & max_exp_event_id==max_trial_event_id),
         xlab = 'Time for full trial events', 
         ylab = 'Event ID')
}


load.avfunctionleaves.df  <- function(con,expid)
{
  
#  query="select tr.experiment_id, tr.id as trial_id, fc.func_id, fc.leafcount, avfc.avg_leafcount, fn.short_name 
#          from trials as tr, func_calls as fc, funcs as fn, program_runs as pr, (select tr.experiment_id, fc.func_id, avg(fc.leafcount) as avg_leafcount
#                                                                                 from trials as tr, func_calls as fc, program_runs as pr                                                          
#                                                                                 where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id
#                                                                                 group by experiment_id,func_id order by avg_leafcount desc limit 20) as avfc
#          where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id and fc.func_id=fn.id and tr.experiment_id=avfc.experiment_id and fc.func_id=avfc.func_id"

 query="select avfc.experiment_id, tr.id as trial_id, avfc.func_id, fc.leafcount, avfc.avg_leafcount, pr.leafcount as total_leafcount, fn.short_name
         from 
         (select tr.experiment_id, fc.func_id, avg(fc.leafcount) as avg_leafcount
            from 
            (select tr.experiment_id, max(eru.event) as max_exp_event_id
              from trials as tr, event_resource_uses as eru
              where tr.experiment_id=%d and tr.id=eru.trial_id group by tr.experiment_id) as mee,
            (select tr.id as trial_id, max(eru.event) as max_trial_event_id
              from trials as tr, event_resource_uses as eru
              where tr.experiment_id=%d and tr.id=eru.trial_id group by trial_id) as met,
            trials as tr, program_runs as pr, func_calls as fc
          where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id and tr.id=met.trial_id and tr.experiment_id=mee.experiment_id and mee.max_exp_event_id=met.max_trial_event_id
          group by tr.experiment_id,func_id order by avg_leafcount desc limit 20) as avfc,
         program_runs as pr, trials as tr, funcs as fn, func_calls as fc
         where avfc.experiment_id=%d and avfc.experiment_id=tr.experiment_id and avfc.func_id=fc.func_id and pr.id=fc.program_run_id and pr.trial_id=tr.id and fc.func_id=fn.id"
 squery<-sprintf(query,expid,expid,expid,expid)
 rs<-dbSendQuery(con,squery)
 df<-fetch(rs,n=-1)
 df$experiment_id <- as.factor(df$experiment_id)
 df$trial_id      <- as.factor(df$trial_id)
 df$short_name    <- substr(df$short_name,1,75)
 df
}

functions.avleaves.plot <- function(df, expids) {
  # print("-------------")
  # print(df)
  # print("-------------")
  bwplot(reorder(as.factor(short_name),leafcount)~leafcount|experiment_id,
         df,
         xlab = 'Leaf Count',
         ylab = 'Function Name')
}


# now repeat it for paths

load.avfunctionpaths.df  <- function(con,expid)
{
# query="select tr.experiment_id, tr.id as trial_id, fc.func_id, fc.pathcount, avfc.avg_pathcount, fn.short_name 
#          from trials as tr, func_calls as fc, funcs as fn, program_runs as pr, (select tr.experiment_id, fc.func_id, avg(fc.pathcount) as avg_pathcount  
#                                                                                 from trials as tr, func_calls as fc, program_runs as pr                                                          
#                                                                                 where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id
#                                                                                 group by experiment_id,func_id order by avg_pathcount desc limit 20) as avfc
#          where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id and fc.func_id=fn.id and tr.experiment_id=avfc.experiment_id and fc.func_id=avfc.func_id"

# use only functions from good trials
  query="select avfc.experiment_id, tr.id as trial_id, avfc.func_id, fc.pathcount, avfc.avg_pathcount, pr.leafcount as total_pathcount, fn.short_name
         from 
         (select tr.experiment_id, fc.func_id, avg(fc.pathcount) as avg_pathcount
            from 
            (select tr.experiment_id, max(eru.event) as max_exp_event_id
              from trials as tr, event_resource_uses as eru
              where tr.experiment_id=%d and tr.id=eru.trial_id group by tr.experiment_id) as mee,
            (select tr.id as trial_id, max(eru.event) as max_trial_event_id
              from trials as tr, event_resource_uses as eru
              where tr.experiment_id=%d and tr.id=eru.trial_id group by trial_id) as met,
            trials as tr, program_runs as pr, func_calls as fc
          where tr.experiment_id=%d and tr.id=pr.trial_id and pr.id=fc.program_run_id and tr.id=met.trial_id and tr.experiment_id=mee.experiment_id and mee.max_exp_event_id=met.max_trial_event_id
          group by experiment_id,func_id order by avg_pathcount desc limit 20) as avfc,
         program_runs as pr, trials as tr, funcs as fn, func_calls as fc
         where avfc.experiment_id=%d and avfc.experiment_id=tr.experiment_id and avfc.func_id=fc.func_id and pr.id=fc.program_run_id and pr.trial_id=tr.id and fc.func_id=fn.id"
 squery<-sprintf(query,expid,expid,expid,expid)
 rs<-dbSendQuery(con,squery)
 df<-fetch(rs,n=-1)
 df$experiment_id <- as.factor(df$experiment_id)
 df$trial_id      <- as.factor(df$trial_id)
 df$short_name    <- substr(df$short_name,1,75)
 df
}

functions.avpaths.plot <- function(df, expids) {
  bwplot(reorder(as.factor(short_name),pathcount)~pathcount|experiment_id,
         subset(df),
         xlab = 'Path Count',
         ylab = 'Function Name')
}

# ---------------------------------------------------------
# Main script begins here
# ---------------------------------------------------------

args<-commandArgs(trailingOnly = TRUE)
if(length(args)!=6) {
  print("Wrong number of arguments")
  print(args)
  q()
}

expid      <- as.numeric(args[1])
drivername <- args[2] 
dbname     <- args[3]
username   <- args[4]
password   <- args[5]
host       <- args[6]

con        <- get.connection(drivername, username, password, host, dbname)

#tr.df   <- load.trials.df(con,expid)
metr.df <- load.metrials.df(con,expid)
#print("trials loaded")

fname="expplot_total_times_exp_%04d.png"
pp<-total.times.plot(metr.df, expid)
generate.png(pp,sprintf(fname,expid,expid))
#print("png created")


fname="expplot_total_times_maxev_exp_%04d.png"
pp<-total.metimes.plot(metr.df, expid)
generate.png(pp,sprintf(fname,expid,expid))

meev.df <- load.meevents.df(con,expid)

#bwplot(event_id~event_time|experiment_id,subset(meev.df,experiment_id %in% 63 & max_exp_event_id==max_trial_event_id))

fname="expplot_event_times_maxev_exp_%04d.png"
pp<-event.metimes.plot(meev.df, expid)
generate.png(pp,sprintf(fname,expid,expid))

# one needs to remove incomplete trials as well...

fnleaves.df <- load.avfunctionleaves.df(con,expid)

fname="expplot_function_leaves_exp_%04d.png"
pp<-functions.avleaves.plot(fnleaves.df, expid)
generate.png(pp,sprintf(fname,expid,expid))
fnpaths.df <- load.avfunctionpaths.df(con,expid)

fname="expplot_function_paths_exp_%04d.png"
pp<-functions.avpaths.plot(fnpaths.df, expid)
generate.png(pp,sprintf(fname,expid,expid))