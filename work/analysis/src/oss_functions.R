###
### Load the sample totals into a trivial data frame.
###  

library(lattice)
library(stringr)
library(sqldf)

### -------------------
### Produce the histogram of total run times.
### -------------------

nevents=100

plot1 <- function(df)
{
  m = mean(df$ntotal)
  s = sd(df$ntotal)
  xmin = 27000
  xmax = 30500
  xs = seq(xmin, xmax, length=nevents)
  ys = dnorm(xs, mean=m, sd = s)
  histogram( ~ntotal
            , data=df
            , type='density'
            , xlab = "Run duration (samples)"
            , ylab = "probability density"
            , nint = 20
            , xlim=c(xmin, xmax)
            , aspect=1/2
            , panel = function(x, breaks, ...)
            {
              panel.histogram(x, breaks)
              panel.lines(xs, ys, lwd=2, col="red")
            }
            )
}

### -------------------
### Make a filesystem path specification into "canonical form".
### Right now, this means replacing multiple "/" by one "/".
### -------------------
canonical.path <- function(pathname)
  {
    str_replace_all(pathname, "/+", "/")
  }

### -------------------
### Extract a run id from a profdata filename. The passed filename is
### expected to be the relative path from TOP, through the CAMPAIGN
### directory, the EXPERIMENT directory, to the data file being
### analyzed.
### -------------------
extract.runid <- function(filename) str_extract(basename(filename), "\\d+_\\d+")

### -------------------
### Extract an experiment id from a profdata filename. The passed
### filename is expected to be the relative path from TOP, through the
### CAMPAIGN directory, the EXPERIMENT directory, to the data file being
### analyzed.
### -------------------
extract.expid <- function(filename)
  {
    parts <- str_split(canonical.path(filename), "/")[[1]]
    str_extract(parts[[2]], "\\d+$")
  }

### -------------------
### Read a single libraries file; this is a helper for load.libraries
### -------------------
read.one.libraryfile <- function(filename)
  {
    
    print(filename)
    
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)
    data.frame( exp = expid
               , run = runid
               , lib = tmp[,1]
               , samples = tmp[,2]
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single run-environment file.
### -------------------
read.one.runenv <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    lines <- readLines(con = filename)
    values.list <- str_split(lines, ":", 2)
    read.list.element = function(idx) { str_trim(values.list[[idx]][[2]]) }
    vendor   <- read.list.element(2)
    family   <- read.list.element(3)
    model    <- read.list.element(4)
    mname    <-
#      gsub("GHz","",
#           gsub("CPU","",
#                gsub("Intel","",
#                     gsub("QuadCore","",
#                          gsub("OpteronProcessor","",
                               gsub("\\(R\\)","",
                                    gsub("\\(tm\\)","",
                                         gsub("-","",
                                              gsub("[[:space:]]","",
                                                   read.list.element(5)))))
                                        #    print(mname)
    stepping <- read.list.element(6)
    
    ## Get the lines with G4 and CMSSW version information.
    ## We take only the first one.

    ## first, we check if this is cmssw or a pure g4 run   
    
    version_lines <- lines[grep("^G4WORKDIR", lines)]

    # print(length(version_lines))
    if (length(version_lines)>0) {
      version_line=version_lines[[1]]
      ## Now take out the 3 pieces of information we care about...
      parts <- str_split(version_line, "/")[[1]]
      ## G4WORKDIR=/uscms_data/d2/user/geant4run/g4.9.4.p01/unmodified/work/N04
      g4 <- parts[[6]]
      ## either 'modified' or 'unmodified'
      mod.or.not <- parts[[7]]
      ## something like N04
      cmssw <- parts[[9]]
    } else {
      ## Get the lines with G4 and CMSSW version information.
      ## We take only the first one.
      version_lines <- lines[grep("^CMSSW_BASE", lines)]
      if (length(version_lines)>0) {
        version_line <- lines[grep("^CMSSW_BASE", lines)][[1]]
        ## Now take out the 3 pieces of information we care about...
        parts <- str_split(version_line, "/")[[1]]
        ## parse things like g4.9.3.p01_cms_3_8_0, picking out g4.9.3.p01
        g4 <- str_split(parts[[6]],"_")[[1]][[1]]
        ## either 'modified' or 'unmodified'
        mod.or.not <- parts[[7]]
        ## something like CMSSW_3_8_0
        cmssw <- parts[[8]]
      } else {
        version_lines <- lines[grep("^MU2E_BASE", lines)]
        if (length(version_lines)>0) {
          version_line <- lines[grep("^MU2E_BASE", lines)][[1]]
          ## Now take out the 3 pieces of information we care about...
          parts <- str_split(version_line, "/")[[1]]
          #print (parts)
          ## parse things like g4.9.4.p01_mu2e_v1_0_9/unmodified/Offline
          g4 <- str_split(parts[[8]],"_")[[1]][[1]]
          ## either 'modified' or 'unmodified'
          mod.or.not <- parts[[9]]
          ## something like mu2e_v1_0_9
          cmssw <- paste("mu2e",str_split(parts[[8]],"_mu2e_")[[1]][[2]],sep="_")
          #print (cmssw)
        }
      }
    }
    # print(sprintf("the run type is %s ",cmssw))
    data.frame( exp = expid
               , run = runid
               , vendor = vendor
               , family = as.integer(family)
               , model = as.integer(model)
               , stepping = as.integer(stepping)
               , mname = mname
               , g4version = g4
               , cmsversion = cmssw
               , modified = mod.or.not
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single names file; this is a helper for load.functions
### -------------------
read.one.functionsfile <- function(filename)
  {    
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)    
    tmp$exp <- expid
    tmp$run <- runid
    ## The str_replace_all call removes the argument list from
    ## function names.
    data.frame( exp = expid
               , run = runid
               , leaf = tmp[,2]
               , path = tmp[,2]
               , leaf.frac = tmp[,3]
               , path.frac = tmp[,3]
               , lib = tmp[,1]
               , mangled = tmp[,1]
               , name = tmp[,1]
               , short = str_replace_all(tmp[,1], "\\([^)]*\\)( const)?", "")
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single libraries file; this is a helper for load.libraries
### -------------------
read.one.callpathsfile <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)    
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)
    data.frame( exp = expid
               , run = runid
               , path = tmp[,2]
               , path.frac = tmp[,3]
               , mangled = tmp[,1]
               , name = tmp[,1]
               , short = str_replace_all(tmp[,1], "\\([^)]*\\)( const)?", "")
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single hwcsamp file; this is a helper for load.hwcsamp
### -------------------
read.one.hwcsampfile <- function(filename)
  {
    
    print(filename)
    
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)
    data.frame( exp = expid
               , run = runid
               , ptime = tmp[,2]
               , cpi = tmp[,3]
               , cyc = tmp[,4]
               , ins = tmp[,5]
               , fp  = tmp[,6]
               , ld  = tmp[,7]
               , mangled = tmp[,1]
               , short = str_replace_all(tmp[,1], "\\([^)]*\\)( const)?", "")
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single event data file; this is a helper for load.event.times
### use User time (5th column) instead of Elapsed (4th column) 
### -------------------
read.one.eventsfile <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    tmp <- read.table(filename, header=FALSE, stringsAsFactors=FALSE)
    names(tmp) <- c("event","t","run")
    data.frame( exp = expid
               , run = runid
               , event = tmp[,2]
               , t = tmp[,5]
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Read a single trial file. The only item we look for is the total
### time reported by TimeReport.
### use time reported by stdout 
### -------------------
#extract.report.time <- function(lines)
#  {
#    matches <- grep(pattern = "Time report complete", x=lines, value=TRUE)
#    parts = str_split(matches, " ")
#    as.double(parts[[1]][[6]])
#  }
extract.report.time <- function(lines)
  {
    matches <- grep(pattern = "TimeTotal>", x=lines, value=TRUE)
    parts = str_split(matches, " ")
    as.double(parts[[1]][[3]])
  }

read.one.trial <- function(filename)
  {
    expid <- extract.expid(filename)
    runid <- extract.runid(filename)
    lines <- readLines(con = filename)
    t <- extract.report.time(lines)
    data.frame( exp = expid
               , run = runid
               , trial.t = t
               , stringsAsFactors = FALSE
               )
  }

### -------------------
### Get all the names of files in the current directory of the given
### FAST "type" as enhanced by the files collected by the CMS timing
### module. The type must be a string, e.g. "libraries" or "names".  We
### return only those files of nonzero size, to avoid problems with
### empty files.
### -------------------

## From the given vector of filenames, return those that correspond to
## non-empty files.
nonempty.files <- function(filenames)
  {
    filenames[file.info(filenames)$size>0]
  }

get.files.for <- function(filetype, subdir)
  {
    allfiles <- list.files( path = subdir
                           , pattern = glob2rx(str_c("ossdata_*_", filetype))
                           , recursive = TRUE
                           , full.names = TRUE
                           )
    nonempty.files(allfiles)
  }

get.aux.files.for <- function(prefix, subdir)
  {
    allfiles <- list.files( path = subdir
                           , pattern = glob2rx(str_c(prefix, "_*.txt"))
                           , recursive = TRUE
                           , full.names = TRUE
                           )
    nonempty.files(allfiles)
  }

### -------------------
### Load all the trials data files under the named directory.
### Use stdout instead of trialdata to get (User+System) time
### -------------------
#load.trials <- function(subdir)
#{
#  tmp <- do.call( rbind
#                 , lapply( get.aux.files.for("trialdata", subdir)
#                          , read.one.trial
#                          )
#                 )
#  tmp
#}
load.trials <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("stdout", subdir)
                          , read.one.trial
                          )
                 )
  tmp
}

### -------------------
### Load all the event data files under the named directory.
### -------------------
load.events <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("eventdata", subdir)
                          , read.one.eventsfile
                          )
                 )
  tmp
}

### -------------------
### Load all the run environments under the named directory.
### -------------------
load.runenvs <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.aux.files.for("run_env", subdir)
                          , read.one.runenv
                          )
                 )
  tmp
}

### -------------------
### Create the RUNMETA dataframe from the RUNENVS dataframe
### -------------------
runmeta.from.runenvs <- function(x)
  {
    subset(x, select=c(exp, run, mname, g4version, cmsversion, modified))
  }

### -------------------
### Load all the totals files under the named directory.
### -------------------
load.totals <- function(subdir)
{
  tmp <- do.call( rbind
                 , lapply( get.files.for("totals", subdir)
                          , read.one.totalsfile
                          )
                 )
  tmp
}

### -------------------
### Load all the libraries files under the named directory.
### -------------------
load.libraries <- function(subdir)
  {
    tmp <- do.call( rbind
                   , lapply( get.files.for("libraries", subdir)
                            , read.one.libraryfile
                            )
                   )
    tmp
  }

### -------------------
### Load all the function call data under the named directory.
### -------------------
load.functions <- function(subdir)
  {
    tmp <- do.call( rbind
                   , lapply( get.files.for("names", subdir)
                            , read.one.functionsfile
                            )
                   )
    tmp
  }

### -------------------
### Load all the function call path data under the named directory.
### -------------------
load.callpaths <- function(subdir)
  {
    tmp <- do.call( rbind
                   , lapply( get.files.for("paths", subdir)
                            , read.one.callpathsfile
                            )
                   )
    tmp
  }

### -------------------
### Load all the hwcsamp data under the named directory.
### -------------------
load.hwcsamp <- function(subdir)
  {
    
    print(subdir)

    tmp <- do.call( rbind
                   , lapply( get.files.for("hwcsamp", subdir)
                            , read.one.hwcsampfile
                            )
                   )
    tmp
  }

### -------------------
### Produce a plot of the "important" libraries. "Important" means they
### have a median count above the cutoff.
### -------------------
plot2 <- function(df, cutoff=0, ...)
  {
    bwplot( reorder(lib, samples.median)~samples
           , subset(df, samples.median>cutoff)
           , panel = function(x,y) { panel.grid(-1,-1); panel.bwplot(x,y) }
           , ...
           )
  }

### -------------------
### Produce a plot of "important" functions. "Important" means they have
### a median leaf count above the cutoff.
### -------------------
plot3 <- function(df, cutoff=0, ...)
  {
    bwplot( reorder(name, leaf.frac.median)~leaf.frac
           , subset(df, leaf.frac.median>cutoff)
           , panel = function(x,y) { panel.grid(-1,-1); panel.bwplot(x,y) }
           , ...
           )
  }

### -------------------
### Produce a QQ plot to test the distribution of leaf fractions for
### "important" functions.
### -------------------
plot4 <- function(df, min.cutoff=0.02, max.cutoff=0.03, ...)
  {
    qqmath( ~leaf.frac|name
           , subset(funcs, leaf.frac.median>min.cutoff & leaf.frac.median<max.cutoff)
           , panel = function(x)
           {
             panel.grid(-1,-1)
             panel.qqmath(x)
             panel.qqmathline(x)
           }
           , xlab = "normal quantiles"
           , ylab = "leaf fraction quantiles"
           , ...
           )
  }

### -------------------
### Produce a plot of functions with high path fraction
### -------------------
plot6 <- function(df, cutoff=0.5, ...)
  {
    bwplot( reorder(abbreviate(name,minlength=30,method="both.sides"), path.frac.median)~path.frac
           , subset(df, path.frac.median>cutoff)
           , panel = function(x,y) { panel.grid(-1,-1); panel.bwplot(x,y) }
           , ...
           )
  }

plot8 <- function(df, run.id="22658", cutoff=10)
  {
    sql <- str_c( "select count(mangled) as nfuncs, lib, run from "
                 , deparse(substitute(df))
                 , " group by lib,run")
    tmp <- sqldf(sql)
    dotplot( reorder(lib, nfuncs)~nfuncs
            , subset(tmp, run==run.id & nfuncs>cutoff)
            , scales = list(x = list( log = 10
                              , at = c(1,10,100,1000)
                              )
                )
            , xlim = c(5,2000)
            , grid = TRUE
            , aspect = 1/2
            , xlab = "functions observed in library"
            )
  }
