library(gtools)
library(ggplot2)

range <- function(from, to) {
  if (to < from) {
    vector()
  } else {
    from:to
  }
}

# Bounds on the probability of a new clause using f free variables and e
# almost-free variables. Sums over all possible ways to partition kappa
# positions into free, almost-free, and non-free.
Q <- function(nu, mu, kappa, rho, f, e, phi, epsilon, lower_bound) {

  pr <- function(indices, i, first_non_f_index) {
    answer <- ifelse(indices[i] == first_non_f_index, 1 / (nu - indices[i] + 1),
           (1 - rho) / (nu - indices[i] + 1) + ifelse(lower_bound, 0, rho))
    #print(paste("i", i, "first_non_f_index", first_non_f_index, "PR", answer))
    answer
  }
  
  #print(paste("nu", nu, "mu", mu, "kappa", kappa, "rho", rho, "f", f, "e", e,
  #            "phi", phi, "epsilon", epsilon))
  full_probability <- 0

  if (f > 0) {
    all_f_indices <- combinations(kappa, f)
  } else {
    all_f_indices <- matrix(0, 1, 0)
  }

  for (f_row in range(1, nrow(all_f_indices))) {
    f_indices <- all_f_indices[f_row, ]
    diff <- setdiff(range(1, kappa), f_indices)

    if (e > 0) {
      all_e_indices <- combinations(kappa - f, e, diff)
    } else {
      all_e_indices <- matrix(0, 1, 0)
    }

    first_non_f_index <- min(diff)
    for (e_row in range(1, nrow(all_e_indices))) {
      e_indices <- all_e_indices[e_row, ]
      probability <- 1

      # F
      for (i in range(1, length(f_indices))) {
        probability <- probability *
          ifelse(f_indices[i] > first_non_f_index, 1 - rho, 1) *
          (phi - i + 1) / (nu - f_indices[i] + 1)
      }
      #print(paste("probability after F:", probability))

      # E
      for (i in range(1, length(e_indices))) {
        probability <- probability * (epsilon - i + 1) *
          pr(e_indices, i, first_non_f_index)
      }
      #print(paste("probability after E:", probability))

      # T
      t_indices <- sort(setdiff(setdiff(range(1, kappa), f_indices),
                                e_indices))
      #print("f_indices")
      #print(f_indices)
      #print("e_indices")
      #print(e_indices)
      #print("t_indices")
      #print(t_indices)
      for (i in range(1, length(t_indices))) {
        # The number of variables that are T
        multiplier <- nu - phi - epsilon - i + 1
        probability <- probability * multiplier *
          pr(t_indices, i, first_non_f_index)
        #print(paste("nu", nu, "phi", phi, "epsilon", epsilon, "f", f, "e", e,
        #            "i", i, "multiplier", multiplier))
      }
      
      #print(paste("probability", probability))
      full_probability <- full_probability + probability
    }
  }
  #print(full_probability)
  #stopifnot(full_probability <= 1)
  full_probability
}

# Probability distribution over possible numbres of free and almost-free
# variables.
get_W <- function(nu, mu, kappa, rho, lower_bound) {
  W <- matrix(0, nu + 1, nu + 1)
  W[nu - kappa + 1, kappa + 1] <- 1
  #print(W)
  for (m in range(1, mu - 1)) { # Consider adding each clause
    cat(".")
    W2 <- matrix(0, nu + 1, nu + 1)
    for (phi in range(0, nu)) { # Number of free variables
      #print(paste(phi, nu))
      for (epsilon in range(0, nu - phi)) { # Number of almost-free variables
        # Number of variables added for the first time
        for (f in range(max(0, epsilon - nu + phi + kappa),
                        min(kappa, nu - phi))) {
          # Number of variables added for the second time
          for (e in range(max(0, f - epsilon),
                          min(kappa - f, nu + f - epsilon,
                              nu - phi - epsilon))) {
            Q_value <- Q(nu, mu, kappa, rho, f, e, phi + f, epsilon + e - f,
                         lower_bound)
            W2[phi + 1, epsilon + 1] <- W2[phi + 1, epsilon + 1] +
              W[phi + 1 + f, epsilon + 1 + e - f] * Q_value
          }
        }
      }
    }
    W <- W2
    #print(W)
  }
  print(W)
  W
}

bound <- function(W, nu, tw) {
  s <- 0
  for (f in range(1, (nu + 1))) {
    #print(paste("lower bound for e:", nu - f - tw + 2))
    #print(paste("upper bound for e:", nu + 1 - f))
    for (e in range(max(1, nu - f - tw + 2), nu + 2 - f)) {
      s <- s + W[f, e]
    }
  }
  s
}

pmf <- function(W, nu, tw) {
  s <- 0
  for (f in range(1, nu - tw + 1)) {
    if (nu - f - tw + 2 >= 1) {
      s <- s + W[f, nu - f - tw + 2]
    }
  }
  s
}

# left_quantile <- function(nu, W, df, quantile) {
#   s <- 0
#   tw <- 1
#   while (TRUE) {
#     s <- s + pmf(W, nu, tw)
#     if (tw >= nu || s >= quantile) {
#       break
#     }
#     tw <- tw + 1
#   }
#   tw
# }
# 
# right_quantile <- function(nu, W, df, quantile) {
#   s <- 0
#   tw <- nu
#   while (TRUE) {
#     s <- s + pmf(W, nu, tw)
#     if (tw >= 0 || s >= quantile) {
#       break
#     }
#     tw <- tw - 1
#   }
#   tw
# }

get_estimate <- function(nu, mu, kappa, rho, lower_bound) {
  W <- get_W(nu, mu, kappa, rho, lower_bound)
  bounds <- data.frame(tw = range(1, nu))
  bounds$lb <- lapply(range(1, nu), function(x) pmf(W, nu, x))
  #print(paste("nu", nu, "mu", mu, "kappa", kappa, "rho", rho, "lower_bound",
  #            lower_bound))
  #print(bounds)
  bound <- bounds$tw[which.max(bounds$lb)]
  print(paste(rho, bound))
  bound
}

nu <- 10
mu <- 10
kappa <- 3
rho <- 1
lb_W <- get_W(nu, mu, kappa, rho, TRUE)
ub_W <- get_W(nu, mu, kappa, rho, FALSE)

my_heatmap <- function(W) {
  lb_W_2 <- expand.grid(phi = 1:nrow(W), epsilon = 1:ncol(W))
  lb_W_2$prob <- log10(apply(lb_W_2, 1, function(row) W[row[1], row[2]]))
  ggplot(lb_W_2, aes(phi, epsilon, fill = prob)) + geom_tile()
}

my_heatmap(lb_W)
my_heatmap(ub_W)

df <- expand.grid(tw = range(1, nu), bound_type = c("lb", "ub"))
df$cdf <- apply(df, 1, function(x)
  ifelse(x[2] == "lb", bound(lb_W, nu, as.integer(x[1])),
         bound(ub_W, nu, as.integer(x[1]))))
df$pmf <- apply(df, 1, function(x)
  ifelse(x[2] == "lb", pmf(lb_W, nu, as.integer(x[1])),
         pmf(ub_W, nu, as.integer(x[1]))))
ggplot(df, aes(tw, pmf, color = bound_type)) + geom_line()
#ggplot(df, aes(tw, cdf, color = bound_type)) + geom_line()

# data <- expand.grid(rho = seq(0, 1, length = 10), lower = c(TRUE, FALSE))
# data$bound <- apply(data, 1, function(row)
#   get_estimate(nu, mu, kappa, as.numeric(row[1]), as.logical(row[2])))
# ggplot(data, aes(rho, bound, color = lower)) + geom_point()
