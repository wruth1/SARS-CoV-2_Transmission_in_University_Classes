data <- read.csv("Data/Output/Outbreak_Size/M=2.csv")
data$threshold <- factor(data$threshold)

# for (i in 2:ncol(data)) {
#     data[, i] <- factor(data[, i])
# }



fit <- lm(size ~ ., data = data)
summary(fit)
# plot(fit, which = 1)