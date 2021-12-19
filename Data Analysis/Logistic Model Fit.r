
library(dplyr)
library(gtools)
library(EQL)

setwd("C:/Users/willi/Desktop/School/Thesis/COVID_Network_Julia")

num_students <- 25627

data <- read.csv("Data/Output/All_Outbreak_Sizes.csv")

num_trials = nrow(data)

# ------------- Replace infinity character in threshold variable ------------- #
thresh <- data$threshold
inds_thresh <- thresh == unique(thresh)[4]
data[inds_thresh, "threshold"] <- "inf"
data$threshold = factor(data$threshold, levels = c("20", "50", "100", "inf"))

for (i in 1:(ncol(data)-1)) {
    data[, i] <- factor(data[, i])
}

for (i in 1:(ncol(data)-2)) {
    levels(data[,i]) <- c("low", "med", "high")
}



par(mfrow = c(3,3))
for (i in 1:(ncol(data)-1)){
  boxplot(data$size ~ data[,i], 
    xlab = names(data)[i], ylab = "Outbreak Size")
}
par(mfrow = c(1,1))
boxplot(data$size ~ data$threshold, 
  xlab = "Threshold", ylab = "Outbreak Size")



get_formula <- function(resp_var, control_var, data){
  model_vars = data %>%
    select(-!!resp_var, -!!control_var) %>%
    names()
  
  # First-order terms
  (form_str <- paste(model_vars, collapse = " + "))
  (form_str <- paste(control_var, form_str, sep = " + "))
  (form_str <- paste(resp_var, form_str, sep = " ~ "))
  
  # Second-order terms. Only include interactions with the control variable
  (form_int_str <- paste(model_vars, control_var, sep = "*"))
  (form_int_str <- paste(form_int_str, collapse = " + "))
  (form_str <- paste(form_str, form_int_str, sep = " + "))
  
  # Convert string to formula object
  form = formula(form_str)
  
  form
}

### Use logistic regression to model proportion who are ever infected

data_logit = data %>%
        mutate(prop = size/num_students) %>%
        select(-size)

## Build formula for logistic regression
form = get_formula("prop", "threshold", data_logit)


## Fit model with and without interactions
fit_glm_main <- glm(prop ~ ., family = quasibinomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
fit_glm_int <- glm(form, family = quasibinomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
# 
# fit_glm_main <- glm(prop ~ ., family = binomial(), 
#   data = data_logit, weights = rep(num_students, times = num_trials))
# fit_glm_int <- glm(form, family = binomial(), 
#   data = data_logit, weights = rep(num_students, times = num_trials))
# 

### Examine model output

## Fitted model summaries
summary(fit_glm_main)
summary(fit_glm_int)

## ANOVA tables
anova(fit_glm_main)
anova(fit_glm_int)

## Get predicted probabilities
pred_main <- predict(fit_glm_main, type = "response")
pred_int <- predict(fit_glm_int, type = "response")

plot(pred_main)
bars = seq(1, length(pred_main), length.out = 28)
abline(v = bars, col = "red")


# ## Display diagnostic plots
# type = 1
# plot(fit_glm_main, which = type)
# plot(fit_glm_int, which = type)


### Get fitted infection probabilities for different thresholds,
### averaged over other parameters' values
fit_glm <- glm(prop ~ threshold, family = binomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
coef_glm = fit_glm$coefficients

a = coef_glm[1]
b = inv.logit(a)
probs = c(b)
for(i in 2:4){
  a = coef_glm[1] + coef_glm[i]
  b = inv.logit(a)
  probs = c(probs, b)
}

probs








### Investigate different overdispersion  ###
### parameters between threshold levels   ###

library(EQL)














############################
### Peak Number of Cases ###
############################

data_peak <- read.csv("data/Output/All_Outbreak_Peaks.csv")

num_trials = nrow(data_peak)

# ------------- Replace infinity character in threshold variable ------------- #
thresh <- data_peak$threshold
inds_thresh <- thresh == unique(thresh)[4]
data_peak[inds_thresh, "threshold"] <- "inf"
data_peak$threshold = factor(data_peak$threshold, levels = c("20", "50", "100", "inf"))

for (i in 1:(ncol(data_peak)-1)) {
  data_peak[, i] <- factor(data_peak[, i])
}

for (i in 1:(ncol(data_peak)-2)) {
  levels(data_peak[,i]) <- c("low", "med", "high")
}



par(mfrow = c(3,3))
for (i in 1:(ncol(data_peak)-1)){
  boxplot(data_peak$peak ~ data_peak[,i], 
    xlab = names(data_peak)[i], ylab = "Peak Case Count")
}
par(mfrow = c(1,1))
boxplot(data_peak$peak ~ data_peak$threshold, 
  xlab = "Threshold", ylab = "Peak Case Count")



# Use logistic regression to model peak proportion of infectious students

data_logit = data_peak %>%
  mutate(prop = peak/num_students) %>%
  select(-peak)

## Build formula for logistic regression
form = get_formula("prop", "threshold", data_logit)

## Fit model with and without interactions
fit_glm_main <- glm(prop ~ ., family = binomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
fit_glm_int <- glm(form, family = binomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))

### Examine model output

## ANOVA tables
anova(fit_glm_main)
anova(fit_glm_int)



###############################
### Proportion of Outbreaks ###
###############################


data_outbreak <- read.csv("data/Output/All_Outbreak_Proportions.csv")

num_trials = nrow(data_outbreak)

# ------------- Replace infinity character in threshold variable ------------- #
thresh <- data_outbreak$threshold
inds_thresh <- thresh == unique(thresh)[4]
data_outbreak[inds_thresh, "threshold"] <- "inf"
data_outbreak$threshold = factor(data_outbreak$threshold, levels = c("20", "50", "100", "inf"))

for (i in 1:(ncol(data_outbreak)-1)) {
  data_outbreak[, i] <- factor(data_outbreak[, i])
}

for (i in 1:(ncol(data_outbreak)-2)) {
  levels(data_outbreak[,i]) <- c("low", "med", "high")
}



par(mfrow = c(3,3))
for (i in 1:(ncol(data_outbreak)-1)){
  boxplot(data_outbreak$Proportion ~ data_outbreak[,i], 
    xlab = names(data_outbreak)[i], ylab = "Peak Case Count")
}
par(mfrow = c(1,1))
boxplot(data_outbreak$Proportion ~ data_outbreak$threshold, 
  xlab = "Threshold", ylab = "Peak Case Count")

table(data_outbreak$Proportion)







# Use logistic regression to model peak proportion of infectious students


## Build formula for logistic regression
form = get_formula("Proportion", "threshold", data_outbreak)

## Fit model with and without interactions
fit_glm_main <- glm(Proportion ~ ., family = binomial(), 
  data = data_outbreak, weights = rep(num_students, times = num_trials))
fit_glm_int <- glm(form, family = binomial(), 
  data = data_outbreak, weights = rep(num_students, times = num_trials))

### Examine model output

## ANOVA tables
anova(fit_glm_main)
anova(fit_glm_int)






##################################################################
### Plot number of cases against number of students in network ###
##################################################################
network_sizes <- c(17851, 25470, 26540, 27307)
all_thresholds = unique(data$threshold)

data_size_comparison <- data %>%
  select(size, threshold)

all_network_sizes = rep(0, times = nrow(data_size_comparison))
for(i in 1:length(network_sizes)){
  this_thresh = all_thresholds[i]
  check_this_thresh = data_size_comparison$threshold == this_thresh
  all_network_sizes[check_this_thresh] = network_sizes[i]
}
data_size_comparison$network = all_network_sizes

with(data_size_comparison, plot(jitter(network), size))
abline(0,1, col="red")

model_vars = names(data)[1:8]
data_mean_size = data %>%
  group_by(threshold, infect_prop_A, infect_prop_I1, infect_param_I2,
    advance_prob_E, advance_prob_A, advance_prob_I1, advance_prob_I2,
    E_to_A_prob) %>%
  summarise(size = mean(size), .groups="drop") %>%
  select(threshold, size)

all_network_sizes = rep(0, times = nrow(data_mean_size))
for(i in 1:length(network_sizes)){
  this_thresh = all_thresholds[i]
  check_this_thresh = data_mean_size$threshold == this_thresh
  all_network_sizes[check_this_thresh] = network_sizes[i]
}
data_mean_size$network = all_network_sizes

with(data_mean_size, plot(jitter(network), size))
abline(0, 1, col="red")

## Get intercept for unthresholded group
mean_full_network = data_mean_size %>%
  filter(threshold == "inf") %>%
  select(size) %>%
  summarise(mean(size))
int = mean_full_network - max(network_sizes)
abline(int, 1, col="red")