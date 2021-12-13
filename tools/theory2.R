library(gtools)

range <- function(from, to) {
  if (to < from) {
    vector()
  } else {
    from:to
  }
}

Q <- function(nu, mu, kappa, rho, f, e, phi, epsilon, lower_bound) {
  pr <- function(indices, i, first_non_f_index) {
    ifelse(indices[i] == first_non_f_index, 1 / (nu - indices[i] + 1),
           (1 - rho) / (nu - indices[i] + 1) + ifelse(lower_bound, 0, rho))
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
          ifelse(f_indices[i] < first_non_f_index, 1 - rho, 1) *
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
      for (i in range(1, length(t_indices))) {
        probability <- probability * (nu - phi - epsilon - i + 1) *
          pr(t_indices, i, first_non_f_index)
      }
      
      #print(paste("probability", probability))
      full_probability <- full_probability + probability
    }
  }
  full_probability
}

get_W <- function(nu, mu, kappa, rho, lower_bound) {
  W <- matrix(0, nu + 1, nu + 1)
  W[nu - kappa, kappa] <- 1
  for (m in range(1, mu - 1)) { # Consider adding each clause
    #print(".")
    W2 <- matrix(0, nu + 1, nu + 1)
    for (phi in range(0, nu)) { # Number of free variables
      #print(paste(phi, nu))
      for (epsilon in range(0, nu)) { # Number of almost-free variables
        # Number of variables added for the first time
        for (f in range(0, min(kappa, nu - phi))) {
          # Number of variables added for the second time
          for (e in range(max(0, f - epsilon),
                          min(kappa - f, nu + f - epsilon))) {
            W2[phi + 1, epsilon + 1] <- W2[phi + 1, epsilon + 1] +
              W[phi + 1 + f, epsilon + 1 + e - f] *
              Q(nu, mu, kappa, rho, f, e, phi + f, epsilon + e - f,
                lower_bound)
          }
        }
      }
    }
    print(W)
    W <- W2
  }
  W
}

bound <- function(W, nu, tw) {
  #print(tw)
  s <- 0
  for (f in range(1, (nu + 1))) {
    for (e in range(1, min(nu + 1, tw - f + 2))) {
      s <- s + W[f, e]
    }
  }
  s
}

nu <- 10
mu <- 30
kappa <- 3
rho <- 0.5
#lb_W <- get_W(nu, mu, kappa, rho, TRUE)
ub_W <- get_W(nu, mu, kappa, rho, FALSE)
#df <- cbind(range(0, nu), bound(lb_W, nu, range(0, nu)),
#            bound(ub_W, nu, range(0, nu)))