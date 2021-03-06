#library("ggplot2") #don't need this if using tidyverse
library(vegan)
library(ggvegan)
library(tidyverse)

install.packages("ggvegan")
  ## use this to install ggvegan if the normal installation method doesn't work
install.packages("remotes")
remotes::install_github("gavinsimpson/ggvegan")


  ## import data via csv-------
okoboji=read.csv("okoboji.csv",header=T)
  ## remove null data/blank cells, and dataset should have 40 observations:
okoboji<-na.omit(okoboji)
head(okoboji) # check column headings
dim(okoboji) # check dimensions, should have 40 cells

  ## Check for outliers and skewness using boxplot:
  ## Right skew: upper whisker is longer than lower whisker, longer tail at higher values
boxplot(okoboji[,c(6:10)]) # tot_chla and cyano are very right skew
boxplot(okoboji[,c(11:17)]) # nitrate and ammonium very right skew

  ## Is the data normally distributed?---------
  ## null hypothesis: data is normally distributed, if p-value <0.05, then data is not normally distributed
  ## In such cases, PCA will not work because it assumes linearity btwn objects and response variables
shapiro.test(okoboji$TDFe)
shapiro.test(okoboji$Y_cyano)

  ## Create a copy of the data and scale data from 0 to 1 ---------
okoboji.scl <- as.data.frame(apply(okoboji[, 6:17], 2, 
                                 function(x) (x - min(x))/(max(x)-min(x))))

  ## Add Date, Site, Month to scaled data:
  ## binds_col() is from dplyr package (within tidyverse)
okoboji.scl<-bind_cols(okoboji.scl,okoboji[,c(2:5)])


  ## Research Question 1------
  ## Do different phytoplankton groups correspond with nutrients?
  ## Use CCA, which compares variables between 2 matrices
  ## Run the CCA --------
  ## code explanation: cca(species data,environmental data)
  ## if neceessary, use [,c()] to define specific columns within the data
ccamodel1<-cca(okoboji.scl[,c(1:5)],okoboji.scl[,c(6:12)])
ccamodel1$CCA # not important unless you want to view scores from CCA, 
autoplot(ccamodel1)

  ## Convert the CCA results into a readable format-----------
  ## Must turn on "ggvegan" package for this to work. 
  ## The command will recognize the CCA
cca.res2<-fortify(ccamodel1, axes = 1:2)

  ## subset sites/samples
site.data<-subset(cca.res2, Score == "sites") 

  ## Add Date, Site, Month to subset data:
  ## binds_col() is from dplyr package (within tidyverse)
site.data<-bind_cols(site.data, okoboji[,c(1:5)])
  
  ## Scale environmental arrows to the plot ---------
  ## subset environmental variables -- these will plot as arrows later
arrows<-subset(cca.res2, Score == "biplot")

  ## multiply the environmental variables (arrows) to scale it to the plot
scores<-c('CCA1','CCA2')
mul<-ggvegan:::arrowMul(arrows[,scores],
                        subset(cca.res2, select = scores, Score == "sites"))

  ## Scales the biplot arrows
arrows[,scores] <-arrows[,scores] * mul


  ## Plot CCA using ggplot---------
ptest2<-ggplot() +
  geom_point(site.data, mapping = aes(x = CCA1, y = CCA2, color = location,
                                      shape = location), size = 3) + #leave out color not wanted
  geom_segment(arrows, mapping = aes(x = 0, xend = CCA1, y = 0, yend = CCA2),
               arrow = arrow(length = unit(0.03, "npc")), # unit = arrow end
               color = "blue", size = 1.5) +
  geom_text(arrows, mapping = aes(label = Label, x = CCA1*1.1, y = CCA2*1.1),
            size = 5) +
  coord_fixed() +
  theme(legend.background = element_rect(fill="white", size=0.3, 
                                         linetype="solid", colour="black"),
        panel.background = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"),
        axis.text=element_text(size=16), axis.title = element_text(size = 16),
        legend.position ="right", legend.key = element_rect(fill = "white"),
        legend.title = element_text(size = 16), legend.text = element_text(size = 16))
ptest2  

