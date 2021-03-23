
library(reshape2)

### suppressPackageStartupMessages(source("/g4/g4p/work/analysis/src/functions.R"))
src_dir <- Sys.getenv( "SRC_DIR" )
suppressPackageStartupMessages(source( file.path( src_dir, "functions.R" ) ))

### -------------------
### Read a single stepping data file; this is a helper for load.stepping
### -------------------

read.one.steppingfile <- function(filename)
  {
    t <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)[,-1]
    names(t) <- c("evt","run","Nstep gamma","Nstep e-","Nstep e+","Nstep pi-","Nstep pi+","Nstep p","Nstep N","Nstep other",
                              "Ntrack gamma","Ntrack e-","Ntrack e+","Ntrack pi-","Ntrack pi+","Ntrack p","Ntrack N","Ntrack other")
    mt = melt(t, id=c("evt","run"))
  }

### -------------------
### Load all stepping data files under the named directory.
### -------------------

load.stepping <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("steppingdata", subdir)
                          , read.one.steppingfile
                          )
                 )
  tmp
}


