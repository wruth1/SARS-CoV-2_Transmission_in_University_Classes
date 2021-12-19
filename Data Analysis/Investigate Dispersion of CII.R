
library(dplyr)
library(magrittr)
library(ggplot2)
library(gridExtra)

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
fit_glm_main <- glm(prop ~ ., family = binomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
fit_glm_int <- glm(form, family = binomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))

fit_glm_main_disper <- glm(prop ~ ., family = quasibinomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))
fit_glm_int_disper <- glm(form, family = quasibinomial(), 
  data = data_logit, weights = rep(num_students, times = num_trials))

## Extract fitted proportions from models with interactions
p_hat_int_raw = predict(fit_glm_int, type = "response")
p_hat_int_disper_raw = predict(fit_glm_int_disper, type = "response")


### Estimate SD of Y in each group empirically
all_SDs_obs = data_logit %>%
  group_by(across(infect_prop_A:threshold)) %>%
  summarise(p_hat_obs = mean(prop), SD_obs = sd(prop), .groups="drop") %>%
  mutate(SD_theo = sqrt((p_hat_obs * (1 - p_hat_obs))/num_students))
all_SDs = all_SDs_obs

### Compute fitted SD from model in each group
data_pred = data_logit %>% select(-prop)
p_hat = predict(fit_glm_main, type = "response")
# Output from predict.glm gives 10 copies of each p_hat. Average over 
# each group using summarise from dplyr to get a single copy
data_pred$p_hat = p_hat
data_p_hats = data_pred %>%
  group_by(across(infect_prop_A:threshold)) %>%
  summarise(p_hat = mean(p_hat), .groups = "drop")
# Extract vector of p_hats
all_p_hats <- data_p_hats$p_hat

all_SDs$p_hat_model = all_p_hats # Add fitted p_hats to data frame
all_SDs %<>% mutate(SD_model = 
    sqrt(p_hat_model*(1-p_hat_model)/num_students)) # Get analytic SD(Y)
                                                          # as predicted by
                                                          # our glm


### Plot observed p_vat vs observed SD
### Also, theoretically predicted SD from binomial model using 
### computed p_hat and corresponding variance
### Note: Superficially, the theoretically predicted variance isn't
###       relevant here, but if it fits more closely, we can use
###       v(mu) = mu^2 (1 - mu)^2 as the variance function
plot_obs = ggplot(data = all_SDs_obs, mapping = aes(x=p_hat_obs)) +
  geom_point(aes(y = SD_obs, color = threshold)) +
  geom_line(aes(y = SD_theo)) +
  ggtitle("Observed Proportion and SD, with Binomial SD formula")
plot(plot_obs)

### There appears to be a lot of inter-group heterogeneity. Plot each
### group on separate axes.

### Plot observed vs binomial predicted SD
plot_SDs_raw = ggplot(data = all_SDs_obs,
  mapping = aes(x = SD_theo, y = SD_obs)) + #, color = threshold)) +
  geom_point() + xlab("Binomial SD") + ylab("Observed SD")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/Global Obs vs Binomial.jpeg"), width = 800, height = 500
  )
plot(plot_SDs_raw)
dev.off()

### Add color based on class size threshold
plot_SDs_col = ggplot(data = all_SDs_obs,
  mapping = aes(x = SD_theo, y = SD_obs, color = threshold)) +
  geom_point() 
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/Color Obs vs Binomial.jpeg") , width = 800, height = 500  
  )
plot(plot_SDs_col)
dev.off()

### Plot different threshold groups on different axes
plot_SDs_facet = ggplot(data = all_SDs_obs,
  mapping = aes(x = SD_theo, y = SD_obs)) + 
  geom_point() + xlab("Binomial SD") + ylab("Observed SD") + 
  facet_wrap(~ threshold, scales = "free", labeller = "label_both") +
  geom_smooth(method = "lm", formula = y~x)
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/Facet Obs vs Binomial.jpeg") , width = 800, height = 500   
  )
plot(plot_SDs_facet)
dev.off()


### Investigate each threshold level separately
### We're not looking to estimate anything here, just to get a feel for
### the data and explore what analysis methods might be appropriate
###   E.g. Is binomial overdispersion present? Yes, almost certainly
###   E.g. Should groups have different overdispersion parameters? Also yes

### Extract and investigate threshold of 20
data_20 = filter(all_SDs_obs, threshold == "20")
fit_20 <- lm(SD_obs ~ SD_theo - 1, data = data_20)
summary(fit_20)

bc_info_20 = MASS::boxcox(fit_20) 
l_hat_20 = bc_info_20$x[which.max(bc_info_20$y)]


plot_20 = ggplot(data_20, aes(x = SD_theo, y = SD_obs)) +
  geom_point() + xlab("Binomial SD") + ylab("Observed SD") +
  geom_smooth(method = "lm", formula = y ~ x - 1)
plot(plot_20)


### Extract and investigate threshold of 50
data_50 <- filter(all_SDs_obs, threshold == "50")

plot_50 = ggplot(data_50, aes(x = SD_theo, y = SD_obs)) +
  geom_point()
plot_50

# Use Box-Cox analysis to identify a niceifying transformation
# Recommends something a bit below 0 (-0.182). Let's use 0
fit_50 <- lm(SD_obs ~ SD_theo, data = data_50)
bc_info_50 = MASS::boxcox(fit_50) 
l_hat_50 = bc_info_50$x[which.max(bc_info_50$y)]

# Plot BC-transformed SDs
# Looks much more linear, and even mostly homoscedastic
data_50 %<>% mutate(SD_obs_trans = log(SD_obs),
  SD_obs_BC = (SD_obs^l_hat_50 - 1)/l_hat_50)
plot_50_trans = ggplot(data_50, aes(x = SD_theo, y = SD_obs_trans)) +
  geom_point() + xlab("Binomial SD") + ylab("log(Observed SD)")
plot_50_trans

plot_50_BC = ggplot(data_50, aes(x = SD_theo, y = SD_obs_BC)) +
  geom_point() + xlab("Binomial SD") + ylab("Box-Cox Observed SD")
plot_50_BC

# Fit a regression model to the transformed data
fit_50_trans <- lm(SD_obs_trans ~ SD_theo, data = data_50)
summary(fit_50_trans)

plot_50_trans_fit = plot_50_trans + geom_smooth(method = "lm")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=50 Obs vs Binomial.jpeg") , width = 800, height = 500 
  )
plot(plot_50_trans_fit)
dev.off()






### Extract and investigate threshold of 100
data_100_raw <- filter(all_SDs_obs, threshold == "100")

plot_100_raw = ggplot(data_100_raw, aes(x = SD_theo, y = SD_obs)) +
  geom_point()
plot_100_raw

ind_out <- which.max(data_100_raw$SD_obs)
print(data_100_raw[ind_out,], width = Inf)


q = data %>%
  filter(infect_prop_A == "low", infect_prop_I1 == "med",
    infect_param_I2 == "low", advance_prob_E == "low",
    advance_prob_A == "med", advance_prob_I1 == "high",
    advance_prob_I2 == "high", E_to_A_prob == "high", 
    threshold == "100")
print(q)


# Remove the outlier
data_100 <- data_100_raw %>%
  filter(SD_obs < 0.15)



plot_100 = ggplot(data_100, aes(x = SD_theo, y = SD_obs)) +
  geom_point() + xlab("Binomial SD") + ylab("Observed SD")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=100 Obs vs Binomial.jpeg") , width = 800, height = 500   
  )
plot(plot_100)
dev.off()


# Use Box-Cox analysis to identify a niceifying transformation
# Recommends something a bit below 0 (-0.26). 
# Let's use explore this value and 0
fit_100 <- lm(SD_obs ~ SD_theo, data = data_100)
bc_info_100 = MASS::boxcox(fit_100) 
l_hat_100 = bc_info_100$x[which.max(bc_info_100$y)]

l_sqrt = -0.5


# Plot BC-transformed SDs
# Looks much more linear, and even mostly homoscedastic
data_100 %<>% mutate(SD_obs_log = log(SD_obs), 
  SD_obs_BC = (SD_obs^ l_hat_100 - 1)/l_hat_100,
  SD_obs_sqrt = (SD_obs^ l_sqrt - 1)/l_sqrt,
  SD_obs_rec = (1 - 1/SD_obs))

plot_100_log = ggplot(data_100, aes(x = SD_theo, y = SD_obs_log)) +
  geom_point() + xlab("Binomial SD") + ylab("log(Observed SD)")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=100 log Obs vs Binomial.jpeg") , width = 800, height = 500   
  )
plot(plot_100_log)
dev.off()

plot_100_BC = ggplot(data_100, aes(x = SD_theo, y = SD_obs_BC)) +
  geom_point() + xlab("Binomial SD") + ylab("BC Observed SD")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=100 BC Obs vs Binomial.jpeg") , width = 800, height = 500   
  )
plot(plot_100_BC)
dev.off()

plot_100_sqrt = ggplot(data_100, aes(x = SD_theo, y = SD_obs_sqrt)) +
  geom_point() + xlab("Binomial SD") + ylab("1 / sqrt(Observed SD)")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=100 rec-sqrt Obs vs Binomial.jpeg") , width = 800, height = 500   
  )
plot(plot_100_sqrt)
dev.off()

plot_100_rec = ggplot(data_100, aes(x = SD_theo, y = SD_obs_rec)) +
  geom_point() + xlab("Binomial SD") + ylab("1 / Observed SD") + 
  geom_smooth(method = "lm")
jpeg(paste0("C:/Users/willi/sfuvault2/CornellStudy/Tex",
  "/Dispersion Analysis/Plots/Obs vs Binomial SD",
  "/T=100 rec Obs vs Binomial.jpeg") , width = 800, height = 500   
)
plot(plot_100_rec)
dev.off()



### Extract and investigate threshold of infinity
data_inf <- filter(all_SDs_obs, threshold == "inf")




###########################################################
### Explore observed SD as a function of observed p_hat ###
###########################################################

# devtools::install_github("lorenzwalthert/strcode", force = TRUE)

### Remove the extreme outlier in the threshold=100 group
all_SDs_obs_old = all_SDs_obs
all_SDs_obs %<>% filter(!((threshold=="100") & SD_obs > 0.15))

### All groups on one axis
varfun_plot = ggplot(all_SDs_obs, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + 
  xlab("Mean Observed CII") + ylab("Observed SD")
jpeg(paste0("C:\\Users\\willi\\sfuvault2\\CornellStudy\\Tex\\",
  "Dispersion Analysis\\Plots\\Obs SD vs CII\\",
  "Global Obs SD vs CII.jpeg"), width = 800, height = 500)
plot(varfun_plot)
dev.off()

### All groups on one axis with theoretical reference line
varfun_plot_ref = ggplot(all_SDs_obs, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + geom_line(aes(y = SD_theo), col = "red") +
  xlab("Observed CII") + ylab("Observed SD")
jpeg(paste0("C:\\Users\\willi\\sfuvault2\\CornellStudy\\Tex\\",
  "Dispersion Analysis\\Plots\\Obs SD vs CII\\",
  "Global Ref Obs SD vs CII.jpeg"), width = 800, height = 500)
plot(varfun_plot_ref)
dev.off()


### All groups on one axis, colored by class size threshold
varfun_color_plot = ggplot(all_SDs_obs, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs, color = threshold)) + 
  xlab("Observed CII") + ylab("Observed SD")
plot(varfun_color_plot)
jpeg(paste0("C:\\Users\\willi\\sfuvault2\\CornellStudy\\Tex\\",
            "Dispersion Analysis\\Plots\\Obs SD vs CII\\",
            "Color Obs SD vs CII.jpeg"), width = 800, height = 500)
plot(varfun_color_plot)
dev.off()


### Plot each group individually and arrange in a grid
varfun_facet_plot = ggplot(all_SDs_obs, aes(y = SD_obs, x = p_hat_obs)) +
  geom_point() +
  facet_wrap(~ threshold, scales = "free", labeller = "label_both") +
  xlab("Observed CII") + ylab("Observed SD") 
jpeg(paste0("C:\\Users\\willi\\sfuvault2\\CornellStudy\\Tex\\",
  "Dispersion Analysis\\Plots\\Obs SD vs CII\\",
  "Facet Obs SD vs CII.jpeg") , width = 800, height = 500 
  )
plot(varfun_facet_plot)
dev.off()

### Threshold = 20
varfun_plot_20 = ggplot(data_20, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + geom_line(aes(y = SD_theo), col = "red") +
  xlab("Observed CII") + ylab("Observed SD") +
  ggtitle("threshold = 20")
plot(varfun_plot_20)

### Threshold = 50
varfun_plot_50 = ggplot(data_50, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + geom_line(aes(y = SD_theo), col = "red") +
  xlab("Observed CII") + ylab("Observed SD") +
  ggtitle("threshold = 50")
plot(varfun_plot_50)

### Threshold = 100
varfun_plot_100 = ggplot(data_100, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + geom_line(aes(y = SD_theo), col = "red") +
  xlab("Observed CII") + ylab("Observed SD") +
  ggtitle("threshold = 100")
plot(varfun_plot_100)

### Threshold = inf
varfun_plot_inf = ggplot(data_inf, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + geom_line(aes(y = SD_theo), col = "red") +
  xlab("Observed CII") + ylab("Observed SD") +
  ggtitle("threshold = inf")
plot(varfun_plot_inf)


### Plot observed SD vs observed CII with reference curve
varfun_facet_plot_ref = ggplot(all_SDs_obs,
  aes(y = SD_obs^2, x = p_hat_obs)) + geom_point() +
  facet_wrap(~ threshold, scales = "free", labeller = "label_both") +
  xlab("Observed CII") + ylab("Observed SD") +
  geom_smooth(method = "lm", formula = y~poly(x,2))
jpeg(paste0("C:\\Users\\willi\\sfuvault2\\CornellStudy\\Tex\\",
  "Dispersion Analysis\\Plots\\Obs SD vs CII\\",
  "Facet Ref Obs SD vs CII.jpeg") , width = 800, height = 500 )
plot(varfun_facet_plot_ref)
dev.off()


### It turns out that the theoretical value is much too small 
### Make new plots with just the observed values

## Threshold = 20
varfun_points_20 = ggplot(data_20, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + 
  xlab("Observed CII") + ylab("Observed SD") +
  ggtitle("threshold = 20")
plot(varfun_points_20)

## Threshold = 50
varfun_points_50 = ggplot(data_50, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + 
  xlab("Observed CII") + ylab("Observed SD")+
  ggtitle("threshold = 50")
plot(varfun_points_50)

## Threshold = 100
varfun_points_100 = ggplot(data_100, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + 
  xlab("Observed CII") + ylab("Observed SD")+
  ggtitle("threshold = 100")
plot(varfun_points_100)

## Threshold = inf
varfun_points_inf = ggplot(data_inf, aes(x = p_hat_obs)) +
  geom_point(aes(y = SD_obs)) + 
  xlab("Observed CII") + ylab("Observed SD")+
  ggtitle("threshold = inf")
plot(varfun_points_inf)






