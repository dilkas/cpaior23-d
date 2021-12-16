library(purrr)
library(plotly)

p0lb <- function(nu, mu, kappa, rho) {
  ((nu - kappa) / nu) ^ mu
}

p0ub <- function(nu, mu, kappa, rho) {
  p1 <- prod(1 - 1 / (nu - 1:(kappa - 1)))
  p2 <- prod(1 - (1 - rho) / (nu - 1:(kappa - 1)))
  (1 - 1 / nu) ^ mu * p1 * p2 ^ (mu - 1)
}

p1lb <- function(nu, mu, kappa, rho) {
  mu * kappa / nu * (1 - 1 / nu) ^ (mu - 1) * (1 - (kappa - 1) / nu) ^ mu
}

p1ub <- function(nu, mu, kappa, rho) {
  p1 <- prod(1 - (1 - rho) / (nu - 1:(kappa - 1))) ^ mu
  inner_product <- function(nu, mu, kappa, rho, k) {
    indices <- setdiff(1:(kappa - 1), k)
    prod(1 - (1 - rho) / (nu - indices)) ^ mu
  }
  k <- 1:(kappa - 1)
  s <- sum(1 / (nu - k) * (1 - (1 - rho) / (nu - k)) ^ (mu - 1) *
             inner_product(nu, mu, kappa, rho, k))
  mu / nu * (1 - 1/nu) ^ (mu - 1) * p1 + mu * (1 - rho) * (1 - 1/nu) ^ mu * s
}

bounds0 <- function(row) {
  if (row[4] == "lb") {
    p0lb(nu, as.numeric(row[1]), kappa, as.numeric(row[2]))
  } else {
    p0ub(nu, as.numeric(row[1]), kappa, as.numeric(row[2]))
  }
}

bounds1 <- function(row) {
  if (row[4] == "lb") {
    p1lb(nu, as.numeric(row[1]), kappa, as.numeric(row[2]))
  } else {
    p1ub(nu, as.numeric(row[1]), kappa, as.numeric(row[2]))
  }
}

pmf <- function(nu, tw, prob) {
  choose(nu, values$tw) * (1 - values$zero - values$one) ^ values$tw *
    (values$zero + values$one) ^ (nu - values$tw)
}

cdf0 <- function(nu, tw, prob) {
  i <- 0:tw
  sum(choose(nu, i) * (1 - prob) ^ i * prob ^ (nu - i))
}

cdf <- function(row) {
  i <- 0:as.numeric(row[3])
  five <- as.numeric(row[5])
  six <- as.numeric(row[6])
  sum(choose(nu, i) * (1 - five - six) ^ i * (five + six) ^ (nu - i))
}

cdf_quantiles <- function(nu, mu, kappa, rho, q, f1, f2) {
  tw <- nu
  prob <- f1(nu, mu, kappa, rho) + f2(nu, mu, kappa, rho)
  while (cdf0(nu, tw, prob) > q) {
    #print(paste0("nu = ", nu, ", mu = ", mu, ", kappa = ", kappa, ", rho = ",
    #             rho, ", q = ", q, ", prob = ", prob, ", tw = ", tw,
    #             ", cdf = ", cdf0(nu, tw, prob)))
    tw <- tw - 1
  }
  #print(paste0("ending with tw = ", tw, " and cdf = ", cdf0(nu, tw, prob)))
  tw
}

facet_data <- function(nu, mu, kappa, rho) {
  alpha <- 0.5
  #print("lower bound")
  tw_lb_0 <- cdf_quantiles(nu, mu, kappa, rho, alpha / 2, p0lb, p1lb)
  tw_lb_1 <- cdf_quantiles(nu, mu, kappa, rho, 1 - alpha / 2, p0lb, p1lb)
  #print("upper bound")
  tw_ub_0 <- cdf_quantiles(nu, mu, kappa, rho, alpha / 2, p0ub, p1ub)
  tw_ub_1 <- cdf_quantiles(nu, mu, kappa, rho, 1 - alpha / 2, p0ub, p1ub)
  c(tw_lb_0, tw_lb_1, tw_ub_0, tw_ub_1)
}

nu <- 100
mu <- unique(as.integer(seq(nu, 15 * nu, length = 100)))
#mu <- nu:(15 * nu)
kappa <- 3
rho <- seq(0, 1, length = 100)
tw <- (0.80 * nu):nu

# bounds on p0, p1
#values <- expand.grid(mu, rho, c("lb", "ub"))
#values <- cbind(values, apply(values, 1, bounds0), apply(values, 1, bounds1))
#names(values) <- c("mu", "rho", "bound_type", "zero", "one")
#plot_ly(values, x = ~mu, y = ~rho, z = ~zero, color = ~bound_type)
#plot_ly(values, x = ~mu, y = ~rho, z = ~one, color = ~bound_type)

# PMF & CDF of tw
values <- expand.grid(mu, rho, tw, c("lb", "ub"))
values <- cbind(values, apply(values, 1, bounds0), apply(values, 1, bounds1))
names(values) <- c("mu", "rho", "tw", "bound_type", "zero", "one")
values$cdf <- apply(values, 1, cdf)
values$pmf <- pmf(nu, values$tw, values$zero + values$one)
plot_ly(colors = c("red", "blue")) %>%
  add_trace(data = values[values$mu == 312 & values$bound_type == "lb",],
            x = ~rho, y = ~tw, z = ~pmf, color = 1, type = 'mesh3d',
            opacity = 1) %>%
  add_trace(data = values[values$mu == 312 & values$bound_type == "ub",],
            x = ~rho, y = ~tw, z = ~pmf, color = 2, type = 'mesh3d',
            opacity = 1) 
