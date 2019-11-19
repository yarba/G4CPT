###
### Produce a "melted" dataframe for the part of experiment 11
### (g4.9.3.p02) run on the Intel hardware.
###

events.melt <- melt(  subset(  events
                             , vendor=="GenuineIntel" & g4version=="g4.9.3.p02" & exp=="11")
                    , id = c("run","event")
                    , measure = c("t")
                    )

### Produce the dataframe for making parallel coordinate plots to look
### at variations across trials for each event.  Each thread
### represents an *event*.
event.thread.plot <- function(...)
  {
    ## events.cast <- cast(events.melt, event~run)
    events.cast <- cast( subset(events.melt, event <= 20), event~run)
    parallel(  events.cast[2:length(events.cast)]
             , common.scale = TRUE
             , xlab = "event processing time (scaled)"
             , ylab = "trial id"
             , aspect = 1/2
             , ...
             )
  }

trial.thread.plot <- function(...)
  {
    trials.cast <- cast(  subset(  events.melt
                                 , event <= 20
                                 )
                        , run~event
                        )
    parallel(  trials.cast[2:length(trials.cast)]
             , common.scale = TRUE
             , xlab = "event processing time (scaled)"
             , ylab = "event number"
             , aspect = 1/2
             , ...
             )
  }

