

library(knitr)
library(dplyr)
library(magrittr)
library(ggplot2)
library(gridExtra)
library(purrr)
library(tibble)
library(ggfortify) # ggplot version of regression diagnostics
library(latex2exp) # Use latex for plot labels with the TeX() function
library(xtable)    # Create latex tables
library(rpart)
library(rpart.plot)


num_students <- 25627

data <-
  read.csv("D:/School/Thesis/COVID_Network_Julia/Data/Output/All_Outbreak_Peaks.csv")

num_trials = nrow(data)

# Number of students remaining in the network for each threshold level
network_sizes <- c(16866, 23660, 24752, 25627)

# ------------- Replace infinity character in threshold variable ------------- #
thresh <- data$threshold
inds_thresh <- thresh == unique(thresh)[4]
data[inds_thresh, "threshold"] <- "inf"
data$threshold = factor(data$threshold, levels = c("20", "50", "100", "inf"))

all_thresholds <- unique(data$threshold)
thresh2size <- function(thresh) {
  switch(
    thresh,
    "20" = network_sizes[1],
    "50" = network_sizes[2],
    "100" = network_sizes[3],
    "inf" = network_sizes[4],
    stop("Invalid threshold level.")
  )
}

for (i in 1:(ncol(data) - 1)) {
  data[, i] <- factor(data[, i])
}

for (i in 1:(ncol(data) - 2)) {
  levels(data[, i]) <- c("low", "med", "high")
}



get_formula <- function(resp_var, control_var, data, int = TRUE) {
  model_vars = data %>%
    select(-!!resp_var,-!!control_var) %>%
    names()
  
  # First-order terms
  (form_str <- paste(model_vars, collapse = " + "))
  (form_str <- paste(control_var, form_str, sep = " + "))
  (form_str <- paste(resp_var, form_str, sep = " ~ "))
  
  # Second-order terms. Only include interactions with the control variable
  if (int) {
    (form_int_str <- paste(model_vars, control_var, sep = "*"))
    (form_int_str <- paste(form_int_str, collapse = " + "))
    (form_str <- paste(form_str, form_int_str, sep = " + "))
  }
  
  # Convert string to formula object
  form = formula(form_str)
  
  form
}


### Build vector of proportions
group_size <- num_trials / 4
all_network_sizes <- rep(network_sizes,
                         each = group_size)
data_logit_raw <- data %>%
  arrange(threshold) %>%
  mutate(network_size = all_network_sizes,
         prop = peak / network_size) %>%
  select(-peak, -network_size)



## Build formula for model fitting
form = get_formula("prop", "threshold", data_logit_raw)


### Estimate SD of Y in each group empirically
all_SDs_obs_raw = data_logit_raw %>%
  group_by(across(infect_prop_A:threshold)) %>%
  summarise(
    p_hat_obs = mean(prop),
    SD_obs = sd(prop),
    .groups = "drop"
  )

all_SDs_obs <- filter(all_SDs_obs_raw,!((threshold == "100") &
                                          (SD_obs > 0.03)))



### Remove extreme outlier from original data frame
row_remove <- all_SDs_obs_raw %>%
  filter((threshold == "100") & (SD_obs > 0.03)) %>%
  select(infect_prop_A:threshold)

data_logit <- data_logit_raw %>%
  filter(!((infect_prop_A %in% row_remove[[1]]) &
             (infect_prop_I1 %in% row_remove[[2]]) &
             (infect_param_I2 %in% row_remove[[3]]) &
             (advance_prob_E %in% row_remove[[4]]) &
             (advance_prob_A %in% row_remove[[5]]) &
             (advance_prob_I1 %in% row_remove[[6]]) &
             (advance_prob_I2 %in% row_remove[[7]]) &
             (E_to_A_prob %in% row_remove[[8]]) &
             (threshold %in% row_remove[[9]])
  ))





#
# Process Data
#
logit <- function(p) {
  log(p / (1 - p))
}

# Compute logit
data_tree <- data_logit %>%
  mutate(logit = logit(prop)) %>% # Apply the logit transform to the response
  # mutate(logit = prop) %>%          # No logit transform
  select(-prop)
colnames(data_tree) <-
  c("rA",
    "rI1",
    "pI2",
    "qE",
    "qA",
    "qI1",
    "qI2",
    "qEA",
    "threshold",
    "logit")






#####################
### Fit Full Tree ###
#####################

for (this_thresh in all_thresholds) {
  print(this_thresh)
  
  fit_full <- data_tree %>%
    filter(threshold == this_thresh) %>%
    select(-threshold) %>%
    rpart(logit ~ .,
          data = .,
          model = T,
          control = rpart.control(cp = 0))
  
  info_full <- fit_full$cptable
  
  ############################
  ### Plot first 25 splits ###
  ############################
  
  plot_by_size(fit_full, 25, type = 0, extra = 0, thresh = this_thresh)
  
  jpeg(
    paste0(
      "D:\\SFU Vault\\CornellStudy\\Tex\\Plots\\Tree_Splits\\Peak-First_25-",
      this_thresh,
      ".jpeg"
    )
  )  
  plot_by_size(fit_full, 25, type = 0, extra = 0, thresh = this_thresh)
  dev.off()
  
  #######################
  ### Fit CV-Min Tree ###
  #######################
  
  ### Get minimum CV error and corresponding CP value
  ind.best = which.min(info_full[, "xerror"])
  CV.best = info_full[ind.best, "xerror"]
  CP.best = info_full[ind.best, "CP"]
  
  ### Get the geometric mean of best CP with one above it
  if (ind.best == 1) {
    ### If minimum CP is in row 1, store this value
    CP.GM = CP.best
  } else{
    ### If minimum CP is not in row 1, average this with the value from the
    ### row above it.
    
    ### Value from row above
    CP.above = info_full[ind.best - 1, "CP"]
    
    ### (Geometric) average
    CP.GM = sqrt(CP.best * CP.above)
  }
  
  
  ### Fit minimum CV error tree
  fit_min = prune(fit_full, cp = CP.best)
  
  ### Get the number of splits in the minimum CV error tree
  ind_min <- which.min(info_full[, "xerror"])
  splits_min <- info_full[ind_min, "nsplit"]
  err_min <- info_full[ind_min, "xerror"]
  
  
  #######################
  ### Fit CV-1SE Tree ###
  #######################
  
  ### Get 1se rule CP value
  err.min = info_full[ind.best, "xerror"]
  se.min = info_full[ind.best, "xstd"]
  threshold = err.min + se.min
  ind.1se = min(which(info_full[1:ind.best, "xerror"] < threshold))
  
  ### Take geometric mean with superior row
  CP.1se.raw = info_full[ind.1se, "CP"]
  if (ind.1se == 1) {
    ### If best CP is in row 1, store this value
    CP.1se = CP.1se.raw
  } else{
    ### If best CP is not in row 1, average this with the value from the
    ### row above it.
    
    ### Value from row above
    CP.above = info_full[ind.1se - 1, "CP"]
    
    ### (Geometric) average
    CP.1se = sqrt(CP.1se.raw * CP.above)
  }
  
  ### Prune the tree
  fit_1se = prune(fit_full, cp = CP.1se)
  
  
  ### Get the number of splits in the 1se tree
  ind_1se <- ind.1se
  splits_1se <- info_full[ind_1se, "nsplit"]
  err_1se <- info_full[ind_1se, "xerror"]
  
  
  
  #####################
  ### Plotting Time ###
  #####################
  
  info <- as_tibble(info_full)
  
  
  ### Plot errors for subtrees of the provided rpart object which do not exceed err
  plot_good <- function(fit, err) {
    this_info <- fit %>%
      .$cptable %>%     # Extract the CP table
      as_tibble() %>%   # Convert to a tibble for dplyr verbs
      filter(xerror <= err) # Remove large errors
    
    this_plot <- ggplot(this_info, aes(x = nsplit, y = xerror)) +
      geom_line() + xlab("Number of Splits") + ylab("CV Error")
    plot(this_plot)
  }
  
  
  
  ##############################################
  ### Plot full trajectory of subtree errors ###
  ##############################################
  
  CV_splits <- c(splits_min, splits_1se)
  CV_errs <- c(err_min, err_1se)

  plot_full <- ggplot(info, aes(x = nsplit, y = xerror)) +
    geom_line() +
    xlab("Number of Splits") + ylab("Relative CV Error") +
    # ggtitle(paste0("CV Errors for CII with Threshold = ", thresh)) +
    ggtitle(paste0("Threshold = ", this_thresh)) +
    theme(plot.title = element_text(hjust = 0.5)) +
    geom_vline(xintercept = CV_splits) + ylim(c(0, NA))
    
  
  plot(plot_full)  
  
  jpeg(
    paste0(
      "D:\\SFU Vault\\CornellStudy\\Tex\\Plots\\Tree_Errors\\Full_Peak_Tree_Errors-",
      this_thresh,
      ".jpeg"
    )
  )
  plot(plot_full)
  dev.off()
  
  
  
  ################################
  ### Plot subtree error rates ###
  ################################
  
  
  ### Get CV errors for reasonably sized subtrees
  tree_sizes <- c(10, 25, 50, 100, 200)
  errs_small <- info %>%
    filter(nsplit %in% tree_sizes) %>%
    select(xerror) %>%
    unlist() %>%
    as_tibble()
  colnames(errs_small) <- "xerror"
  
  plot_sizes <-
    ggplot(info[1:max(tree_sizes), ], aes(x = nsplit, y = xerror)) +
    geom_line() + ylim(c(0, max(info$xerror))) +
    geom_hline(yintercept = min(info$xerror), color = "red") +
    geom_vline(xintercept = tree_sizes, color = "blue") +
    geom_rug(
      data = errs_small,
      mapping = aes(y = xerror),
      inherit.aes = F,
      color = "blue"
    ) +
    xlab("Number of Splits") + ylab("Relative CV Error") +
    # ggtitle(paste0("CV Errors for CII with Threshold = ", thresh)) +
    ggtitle(paste0("Threshold = ", this_thresh)) +
    theme(plot.title = element_text(hjust = 0.5))
  
  plot(plot_sizes)
  
  jpeg(
    paste0(
      "D:\\SFU Vault\\CornellStudy\\Tex\\Plots\\Tree_Errors\\Focused_Peak_Tree_Errors-",
      this_thresh,
      ".jpeg"
    )
  )
  plot(plot_sizes)
  dev.off()
  
}