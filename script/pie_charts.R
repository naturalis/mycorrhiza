# apologies for there not being a generalized solution here. The point is that 
# all subsequent paths will be constructed relative to the location of the
# script folder. BTW I just run this inside RStudio and write the pie charts
# to separate files using GUI commands (Export... in the Plots tab)
setwd("~/Documents/local-projects/mycorrhiza/script")

# define the colors for the pie charts, same as visualize.pl and d3.html
colors <- c(
  "#dbdcad", # AB
  "#95a41b", # B
  "#5d919e", # BG
  "#6ad6f6", # G
  "#21bff3", # GM
  "#5a5f1a", # ABG
  "#18558a", # M
  "#d16115", # -
  "#e0cf2c"  # A
)

# setup variables for data file locations
rootings <- c("ABasal", "ATxMB", "MBasal", "TBasal")
datadir <- "../data/2017-03-06"

# this function draws the actual pie chart
drawPie <- function(root) {
    
  # read the tables for the three runs
  run1 <- read.delim( file.path( datadir, root, "run1.tsv" ), row.names = 1 )
  run2 <- read.delim( file.path( datadir, root, "run2.tsv" ), row.names = 1 )
  run3 <- read.delim( file.path( datadir, root, "run3.tsv" ), row.names = 1 )
  
  # compute the average over the three runs
  merged = ( run1 + run2 + run3 ) / 3
  
  # plot the pie chart
  pie(
    merged$posterior,
    labels = row.names(merged),
    edges = 200, # the circular outline of the pie is approximated by a polygon with this many edges.
    radius = 0.8, # pie is centered in a square box ranging from -1 to 1. If slice labels are long use a smaller radius.
    col = colors,        
  )
  return(merged)
}

# now draw the pies for each rooting
merged.abasal<-drawPie("ABasal")
merged.atxmb<-drawPie("ATxMB")
merged.mbasal<-drawPie("MBasal")
merged.tbasal<-drawPie("TBasal")

