
### suppressPackageStartupMessages(source("analysis/src/oss_functions.R"))
src_dir <- Sys.getenv( "SRC_DIR" )
suppressPackageStartupMessages(source( file.path( src_dir, "oss_functions.R" ) ))

### -------------------
### Read a single memory data file; this is a helper for load.memory.times
### -------------------

read.one.memoryfile <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)
    names(tmp) <- c("event","vsize","rss","share","run")
    data.frame(  exp = expid
               , run = runid
               , event = tmp[,2]
               , vsize = tmp[,4]
               , rss = tmp[,5]
               , share = tmp[,6]
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Load all the memory data files under the named directory.
### -------------------

load.memory <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("memorydata", subdir)
                          , read.one.memoryfile
                          )
                 )
  tmp
}

### -------------------
### Read a single trial file. The only item we look for is the total
### memory reported by MemoryReport.
### -------------------
extract.report.vsize <- function(lines)
  {
    matches <- grep(pattern = "Memory report complete", x=lines, value=TRUE)
    parts = str_split(matches, " ")
    as.double(parts[[1]][[6]])
  }
extract.report.rss <- function(lines)
  {
    matches <- grep(pattern = "Memory report complete", x=lines, value=TRUE)
    parts = str_split(matches, " ")
    as.double(parts[[1]][[7]])
  }
extract.report.share <- function(lines)
  {
    matches <- grep(pattern = "Memory report complete", x=lines, value=TRUE)
    parts = str_split(matches, " ")
    as.double(parts[[1]][[8]])
  }

read.one.vsize <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    lines <- readLines(con = filename)
    vsize <- extract.report.vsize(lines)
    rss   <- extract.report.rss(lines)
    share <- extract.report.share(lines)
    data.frame( exp = expid
               , run = runid
               , run.vsize = vsize
               , run.rss   = rss
               , run.share = share
               , stringsAsFactors = FALSE
               )
  }
### -------------------
### Load all the run memory data files under the named directory.
### -------------------
load.runmemory <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("stdout", subdir)
                          , read.one.vsize
                          )
                 )
  tmp
}
