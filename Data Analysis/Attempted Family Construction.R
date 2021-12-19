View(glm.fit)
View(summary.glm)

num_students <- 25627


logitexp <- function(days = 1)
{
  linkfun <- function(mu) qlogis(mu^(1/days))
  linkinv <- function(eta) plogis(eta)^days
  mu.eta  <- function(eta) days * plogis(eta)^(days-1) *
    binomial()$mu.eta(eta)
  valideta <- function(eta) TRUE
  link <- paste0("logexp(", days, ")")
  structure(list(linkfun = linkfun, linkinv = linkinv,
    mu.eta = mu.eta, valideta = valideta, name = link),
    class = "link-glm")
}
(bil3 <- binomial(logexp(3)))


fam <- binomial()
str(fam)
fam$dev.resids


a <-  3738

library(pracma)


### Compute deviance residuals from my log-transformed quasi-binomial model
### The functional form is obtained by integrating in Maple
### Note: I am handling weights by using them to multiply the residual
###       This is equivalent to applying V(Y, wt) = V(Y)/wt
dev.resids_50 <- function(y, mu, wt){
  R1 = exp(a*y*(y-1)/wt) - exp(a*mu*(mu-1)/wt)
  R1 = wt* R1 / a
  
  R2 = (y-0.5)*sqrt(pi)*exp(-a/(4*wt))/sqrt(a/wt)
  
  log(abs(y-0.5)*sqrt(wt*pi/a))
  
  R3 = erfi(sqrt(a/wt)*(2*y - 1)/2) - 
    erfi(sqrt(a/wt)*(2*mu - 1)/2)
  
  R = R1 + R2*R3
  
  
  ### Need to take sqrt and account for sign
  d <- sqrt(R) * sign(y - mu)
  return(d)
}


poly_dev.resids_50 <- function(y, mu, wt){
  a <-  0.0172
  b <- -0.177
  c <- 0.00151
  
  # Intermediate values
  d <- sqrt(as.complex(4*a*c - b^2))
  e <- atan((2*a*mu + b)/d)
  
  R1 <- log(a*mu^2 + b*mu + c)/a
  
  R2 <- 4*e*y/d
  
  R3 <- 2*e*b/(a*d)
  
  R <- R2 + R3 - R1
}

dev.resids_50(0.002, 0.003, num_students)



### Be very very careful: wt must be set to 1, unlike for 
###                       regular logistic regression!
### (weights have been accounted for in construction of
### the variance function)
varfun_50 <- function(mu){
  mu * (1 - mu)
}
validmu_50 <- function(mu) all(mu > 0) && all(mu < 
    1)
initialize_50 <- expression({
  mystart <- pmax(0.001, pmin(0.999, y)) # From quasi()
})



variance_50 <- list(
  varfun = varfun_50,
  validmu = validmu_50,
  dev.resids = dev.resids_50,
  initialize = initialize_50,
  name = "My_Variance_50"
)

q <- quasi(link = "logit", variance = "mu^2")


my_link_50 <- quasi(link = "logit", variance = variance_50)

test <- glm(prop ~ ., family = my_link_50, 
  data = data_logit, 
  weights = rep(num_students, times = nrow(data_logit)),
  mustart = y)

glm_int_quad <- glm(form, data = data_logit, 
  family = quasi(link = "logit", variance = "mu^2"),
  weights = rep(num_students, times = nrow(data_logit)))

glm_main_quad <- glm(prop ~ ., data = data_logit, 
  family = quasi(link = "logit", variance = "mu^2"),
  weights = rep(num_students, times = nrow(data_logit)))

glm_int_bin <- glm(form, data = data_logit, 
  family = quasibinomial(),
  weights = rep(num_students, times = nrow(data_logit)))

glm_main_bin <- glm(prop ~ ., data = data_logit, 
  family = quasibinomial(),
  weights = rep(num_students, times = nrow(data_logit)))


pieces <- names(q)

i=12
q[pieces[i]]
my_link_50[pieces[i]]
