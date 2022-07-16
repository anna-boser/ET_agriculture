library(data.table)
library(here)
library(ggplot2)
library(dplyr)

data <- read.csv(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))

# remove monthgroups
data <- pivot_wider(data, names_from = c(monthgroup), values_from = c(ET, PET))

data$ET <- rowMeans(select(data, ET_2, ET_3, ET_4), na.rm = FALSE)
data$PET <- rowMeans(select(data, PET_2, PET_3, PET_4), na.rm = FALSE)

data <- data %>% select(-ET_2, -ET_3, -ET_4, -PET_2, -PET_3, -PET_4)

# remove any NA values
data <- filter(data, !(is.na(ET)))

# look at the distribution of ET values
summary(data$ET)

# keep the top 10% to inspect
inspect <- filter(data, ET>2.5)
write.csv(inspect, "~/Downloads/inspect.csv")

# plot out in ggplot
ggplot(inspect) + 
  geom_point(aes(x = x, y = y, color = ET)) + 
  scale_fill_gradientn(name="ET (mm/day)", colours = c("darkgoldenrod4", "darkgoldenrod2", "khaki1", "lightgreen", "turquoise3", "deepskyblue3", "mediumblue", "navyblue", "midnightblue", "black"), limits = c(-2.5, 8))
