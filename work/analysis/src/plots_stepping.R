###
### These functions all assume that the TRIALS, EVENTS, FUNCTIONS and
### LIBRARIES dataframes are already loaded.
###

nstep.particle.plot <- function(...)
  {
    bwplot(  variable~value 
           , stepping
           , panel = function(x,y) { panel.grid(0, -1); panel.bwplot(x,y) }
           , xlab = "Number of Steps/Tracks"
           , aspect = 1/2
           , ...
           )
  }

