###
### These functions all assume that the TRIALS, EVENTS, FUNCTIONS and
### LIBRARIES dataframes are already loaded.
###

nevents=100

basic.trial.times.plot <- function(...)
  {
    bwplot(  ~trial.t | mname + cmsversion + g4version
           , trials
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y) }
           , xlab = "total trial time (s)"
           , aspect = 1/2
           , ...
           )
  }

basic.trial.times.histogram <- function(...)
  {
    histogram(  ~trial.t | mname + cmsversion + g4version
              , trials
              , nint = 80
              , type = 'c'
              , xlab = "total trial time (s)"
              , aspect = 1/2
              , ...
              )
  }

early.events.plot <- function( firstevent = 1, lastevent = 10, ...)
  {
    bwplot(  event~t | mname + cmsversion + g4version
           , subset( events, firstevent <= event & event <= lastevent)
           , xlab = "event processing time (s)"
           , ylab = "event number"
           , aspect = 1/2
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

all.events.plot <- function(firstevent = 1, lastevent = nevents, ... )
  {
    bwplot(  event~t | mname + cmsversion + g4version
           , subset( events, firstevent <= event & event <= lastevent)
           , scales = list( y=list(at = seq(0,nevents,by=10), labels = seq(0,nevents,by=10)))
           , xlab = "event processing time (s)"
           , ylab = "event number"
           , aspect = 1/2
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

big.functions.count.plot <- function( minfrac = 0.018, ...)
  {
    bigfuncs <- subset(functions, max.leaf.frac.median > minfrac)
    bwplot(  reorder(short, max.leaf.frac.median)~leaf | mname + cmsversion + g4version
           , bigfuncs
           , aspect = 1/2
           , xlab = "leaf count"
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

big.functions.frac.plot <- function( minfrac = 0.018, maxfracsc = 0.1, ...)
  {
    bigfuncs <- subset(functions, max.leaf.frac.median > minfrac)
    bwplot(  reorder(short, max.leaf.frac.median)~leaf.frac | mname + cmsversion + g4version
           , bigfuncs
           , aspect = 1/2
           , xlab = "leaf fraction", xlim = c(0.,maxfracsc)
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

big.paths.count.plot <- function( minfrac = 0.16, maxfrac = 0.90, ...)
  {
    bigfuncs <- subset(callpaths, minfrac < max.path.frac.median & max.path.frac.median < maxfrac  )
    bwplot(  reorder(substr(short,1,min(50,length(short))), max.path.frac.median)~path |
           mname + cmsversion + g4version
           , bigfuncs
           , aspect = 1/2
           , xlab = "path count"
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

big.paths.frac.plot <- function( minfrac = 0.16, maxfrac = 0.90, ...)
  {
    bigfuncs <- subset(callpaths, minfrac < max.path.frac.median & max.path.frac.median < maxfrac  )
    bwplot(  reorder(substr(short,1,min(50,length(short))), max.path.frac.median)~path.frac |
           mname + cmsversion + g4version
           , bigfuncs
           , aspect = 1/2
           , xlab = "path fraction", xlim = c(0.,1.)
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

big.libraries.count.plot <- function( minmed = 10, ...)
  {
    bigfuncs <- subset(libraries,  max.samples.median > minmed )
    bwplot(  reorder(lib, max.samples.median)~samples |
           mname + cmsversion + g4version
           , bigfuncs
           , aspect = 1/2
           , xlab = "lib count"
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

