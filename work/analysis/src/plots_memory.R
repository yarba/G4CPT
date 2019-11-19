nevents=200

memory.share.plot <- function( firstevent = 1, lastevent = nevents, ...)
  {
    bwplot(  event~share | mname + cmsversion + g4version
           , subset( memory, firstevent <= event & event <= lastevent)
           , scales = list( y=list(at = seq(0,nevents,by=10), labels = seq(0,nevents,by=10)))
           , xlab = "Memory SHARE (MB)"
           , ylab = "Event Number"
           , aspect = 1/2
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

memory.rss.plot <- function( firstevent = 1, lastevent = nevents, ...)
  {
    bwplot(  event~rss | mname + cmsversion + g4version
           , subset( memory, firstevent <= event & event <= lastevent)
           , scales = list( y=list(at = seq(0,nevents,by=10), labels = seq(0,nevents,by=10)))
           , xlab = "Memory RSS (MB)"
           , ylab = "Event Number"
           , aspect = 1/2
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }
memory.vsize.plot <- function( firstevent = 1, lastevent = nevents, ...)
  {
    bwplot(  event~vsize | mname + cmsversion + g4version
           , subset( memory, firstevent <= event & event <= lastevent)
           , scales = list( y=list(at = seq(0,nevents,by=10), labels = seq(0,nevents,by=10)))
           , xlab = "Memory VSIZE (MB)"
           , ylab = "Event Number"
           , aspect = 1/2
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y,pch=20,...) }
           )
  }

#--------------------------------
# Run Summary: Vsize, Rss, Share
#--------------------------------

memory.run.vsize.plot <- function(...)
  {
    bwplot(  ~run.vsize | mname + cmsversion + g4version
           , runmemory
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y) }
           , xlab = "End Run VSIZE (MB)"
           , aspect = 1/2
           , ...
           )
  }

memory.run.vsize.histogram <- function(...)
  {
    histogram(  ~run.vsize | mname + cmsversion + g4version
              , runmemory
              , nint = 80
              , type = 'c'
              , xlab = "End Run VSIZE (MB)"
              , aspect = 1/2
              , ...
              )
  }

memory.run.rss.plot <- function(...)
  {
    bwplot(  ~run.rss | mname + cmsversion + g4version
           , runmemory
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y) }
           , xlab = "End Run RSS (MB)"
           , aspect = 1/2
           , ...
           )
  }

memory.run.rss.histogram <- function(...)
  {
    histogram(  ~run.rss | mname + cmsversion + g4version
              , runmemory
              , nint = 80
              , type = 'c'
              , xlab = "End Run RSS (MB)"
              , aspect = 1/2
              , ...
              )
  }

memory.run.share.plot <- function(...)
  {
    bwplot(  ~run.share | mname + cmsversion + g4version
           , runmemory
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y) }
           , xlab = "End Run SHARE (MB)"
           , aspect = 1/2
           , ...
           )
  }

memory.run.share.histogram <- function(...)
  {
    histogram(  ~run.share | mname + cmsversion + g4version
              , runmemory
              , nint = 80
              , type = 'c'
              , xlab = "End Run SHARE (MB)"
              , aspect = 1/2
              , ...
              )
  }
