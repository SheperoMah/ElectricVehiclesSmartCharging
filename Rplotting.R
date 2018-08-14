library(ggplot2)
library(tidyverse)
library(R.matlab)
library(reshape2)
library("gridExtra")

rm(list= ls())
setwd("/Users/mahmoudshepero/documents/MATLAB/smartCharging/singleHouseModel")
listResults = readMat('resultsSimulation9Aug2018.mat')
controlResults = readMat('resultsControlled.mat')
valleyResults = readMat('resultsValley.mat')$resultsValley[,,1]
plottedresults = controlResults$resultsControl[,,1]
data <- listResults$controlled[,,]

cp = factor(listResults$chargingPower/1000)
pl = factor(listResults$powerLimit/1000)
chargingPower = listResults$chargingPower
nCps <- dim(chargingPower)[2]
powerLimit = listResults$powerLimit
nPl <- dim(powerLimit)[2]
idxCancelled <- t(chargingPower) %*% matrix(1, 1, nPl) >= 
  matrix(1, nCps, 1) %*% powerLimit 



avgPeakRed = matrix(rowMeans(data$reducedPeak, dims = 2), nrow = nCps, ncol = nPl,
              dimnames = list(cp, pl))
avgPeakRed[idxCancelled] = NaN

avgCountExt = plottedresults$avgCountExtension; rownames(avgCountExt) <- cp ; colnames(avgCountExt) <- pl
maxCountExt = plottedresults$maxCountExtension; rownames(maxCountExt) <- cp ; colnames(maxCountExt) <- pl
maxDurationExt =plottedresults$maxDurExt; rownames(maxDurationExt) <- cp ; colnames(maxDurationExt) <- pl
meanDurationExt = plottedresults$avgDurExt; rownames(meanDurationExt) <- cp ; colnames(meanDurationExt) <- pl


valleyResults <- lapply(valleyResults, function(x) {
  colnames(x) <- pl
  return(x)})

valleyResults <- lapply(valleyResults, function(x) {
  rownames(x) <- cp
  return(x)})


plotHeatMap <- function(inputMatrix, xlab, ylab, fntsz){
  melted_cormat <- melt(inputMatrix, na.rm = T) 
  melted_cormat$Var1 = factor(melted_cormat$Var1)
  melted_cormat$Var2 = factor(melted_cormat$Var2)
  
  p <- ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(width=0.9, height=.9) +
    geom_text(aes(label = round(value,1)), color = "black", size = 4) +
    scale_fill_gradient2(low = "yellow", high = "red", 
                         midpoint = mean(melted_cormat$value), 
                         limits = c(min(melted_cormat$value),
                                   max(melted_cormat$value)),
                         guide = FALSE ) +
    theme_minimal() +
    scale_x_discrete(xlab) + 
    scale_y_discrete(ylab) + 
    theme(axis.text = element_text(size=fntsz), 
          axis.title = element_text(size=fntsz))
  return(p)
}

plotHeatMapTime <- function(inputMatrix, xlab, ylab, fntsz){
  melted_cormat <- melt(inputMatrix, na.rm = T) 
  melted_cormat$Var1 = factor(melted_cormat$Var1)
  melted_cormat$Var2 = factor(melted_cormat$Var2)
  
  
  p <- ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(width=0.9, height=.9) +
    geom_text(aes(label = paste(sprintf("%02d",floor(value/60)), ":", sprintf("%02d",value%%60), sep = "")),
              color = "black", size = 4) +
    scale_fill_gradient2(low = "yellow", high = "red", 
                         midpoint = mean(melted_cormat$value), 
                         limit = c(min(melted_cormat$value),
                                   max(melted_cormat$value)),
                         guide = FALSE ) +
    theme_minimal() +
    scale_x_discrete(xlab) + 
    scale_y_discrete(ylab) + 
    theme(axis.text = element_text(size=fntsz), 
          axis.title = element_text(size=fntsz))
  return(p)
}

#################################
# plot the controlled charging code

fntsz = 15
plotAvgPeakRed = plotHeatMap(avgPeakRed/1000, "Charging power (kW)", "Fuse size (kW)", fntsz)

plotAvgCountExt = plotHeatMap(avgCountExt, "Charging power (kW)", "Fuse size (kW)", fntsz)
plotMaxCountExt = plotHeatMap(maxCountExt, "Charging power (kW)", "Fuse size (kW)", fntsz)

plotmaxDurationExt = plotHeatMapTime(maxDurationExt, "Charging power (kW)", "Fuse size (kW)", fntsz)

plotmeanDurationExt = plotHeatMapTime(meanDurationExt, "Charging power (kW)", "Fuse size (kW)", fntsz)

p1 = plotAvgCountExt + ggtitle("(a)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p2 = plotMaxCountExt + ggtitle("(b)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p3 = plotmeanDurationExt + ggtitle("(c)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p4 = plotmaxDurationExt + ggtitle("(d)")+ theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p5 <- grid.arrange(p1, p2, p3, p4, ncol = 2)

ggsave("resultsCountsExtandDur.pdf", 
       plot = p5, # or give ggplot object name as in myPlot,
       width = 20, height = 20, 
       units = "cm", # other options c("in", "cm", "mm"), 
       dpi = 300)



######################
# plot the valley filling code
plotMaxCountExt = plotHeatMap(valleyResults$maxCountExt, "Charging power (kW)", "Fuse size (kW)", fntsz)
plotHeatMapWithCustomScale <- function(inputMatrix, xlab, ylab, fntsz){
  library("scales")
  melted_cormat <- melt(inputMatrix, na.rm = T) 
  melted_cormat$Var1 = factor(melted_cormat$Var1)
  melted_cormat$Var2 = factor(melted_cormat$Var2)
  
  p <- ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(width=0.9, height=.9) +
    geom_text(aes(label = round(value,1)), color = "black", size = 4) +
    scale_fill_gradientn(colors = c("yellow", "red"), 
                         values = rescale(c(min(melted_cormat$value),
                                    max(melted_cormat$value))),
                         guide = FALSE ) +
    theme_minimal() +
    scale_x_discrete(xlab) + 
    scale_y_discrete(ylab) + 
    theme(axis.text = element_text(size=fntsz), 
          axis.title = element_text(size=fntsz))
  return(p)
}
plotMinCountRed = plotHeatMapWithCustomScale(valleyResults$minCountReduc, "Charging power (kW)", "Fuse size (kW)", fntsz)

plotmaxDurationExt = plotHeatMapTime(valleyResults$maxDurationExt, "Charging power (kW)", "Fuse size (kW)", fntsz)

plotmeanDurationReduction = plotHeatMapTime(ceiling(valleyResults$avgDurationReduc), "Charging power (kW)", "Fuse size (kW)", fntsz)

p1 = plotMaxCountExt + ggtitle("(a)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p2 = plotMinCountRed + ggtitle("(b)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p3 = plotmaxDurationExt + ggtitle("(c)") + theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p4 = plotmeanDurationReduction + ggtitle("(d)")+ theme(plot.title = element_text(hjust = 0.5, size = fntsz))
p5 <- grid.arrange(p1, p2, p3, p4, ncol = 2)


ggsave("resultsValleyFilling.pdf", 
       plot = p5, # or give ggplot object name as in myPlot,
       width = 20, height = 20, 
       units = "cm", # other options c("in", "cm", "mm"), 
       dpi = 300)





