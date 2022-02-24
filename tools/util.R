TIMEOUT <- 500
IQR1 <- 0.25
IQR2 <- 0.75

read_data <- function(filename) {
  data <- read.csv(filename)
  # What proportion of instances run out of memory?
  print("ran out of memory")
  print("overall")
  overall <- sum(is.na(data$answer) & data$time < TIMEOUT) / nrow(data)
  print(overall)
  print("cachet")
  print(sum(data$algorithm == "cachet" & is.na(data$answer) &
              data$time < TIMEOUT) / nrow(data) / overall)
  print("c2d")
  print(sum(data$algorithm == "c2d" & is.na(data$answer) &
              data$time < TIMEOUT) / nrow(data) / overall)
  print("d4")
  print(sum(data$algorithm == "d4" & is.na(data$answer) &
              data$time < TIMEOUT) / nrow(data) / overall)
  print("dpmc")
  print(sum(data$algorithm == "dpmc" & is.na(data$answer)
            & data$time < TIMEOUT) / nrow(data) / overall)
  print("minic2d")
  print(sum(data$algorithm == "minic2d" & is.na(data$answer)
            & data$time < TIMEOUT) / nrow(data) / overall)
  # What proportion of instances time out?
  print("timed out")
  print(sum(data$time >= TIMEOUT) / nrow(data))
  data$time[data$time >= TIMEOUT] <- TIMEOUT
  data <- data[data$time >= TIMEOUT | !is.na(data$answer),]
  data$algorithm[data$algorithm == "c2d"] <- "\\textsc{c2d}"
  data$algorithm[data$algorithm == "cachet"] <- "\\textsc{Cachet}"
  data$algorithm[data$algorithm == "d4"] <- "\\textsc{d4}"
  data$algorithm[data$algorithm == "dpmc"] <- "\\textsc{DPMC}"
  data$algorithm[data$algorithm == "minic2d"] <- "\\textsc{miniC2D}"
  return(data)
}

plot_with_sd <- function(df, x_value, x_label) {
  df <- df %>% summarise(mean = median(time),
                         lb = unname(quantile(time, IQR1)),
                         ub = unname(quantile(time, IQR2)))
  ggplot(df, aes(.data[[x_value]], mean, group = algorithm, colour = algorithm,
                 fill = algorithm, linetype = algorithm, shape = algorithm)) +
    geom_line() +
    geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25, linetype = 0) +
    xlab(x_label) +
    ylab("Time (s)") +
    labs(color = "", fill = "", linetype = "", shape = "") +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    scale_linetype_manual(values = c("twodash", "dotted", "dotdash", "solid",
                                     "longdash")) +
    theme_set(theme_gray(base_size = 9))
}

fit_model <- function(algorithm, clause_factor) {
  df <- data[data$algorithm == algorithm &
               data$clause_factor == clause_factor,] %>%
    group_by(treewidth) %>% summarise(time = median(time))
  model <- lm(log(df$time) ~ df$treewidth)
  sum <- summary(model)
  print(sum)
  return(c(sum$coefficients[2, 1], sum$coefficients[2, 2], sum$r.squared))
}

plot_4_plots <- function(data, fits) {
  data3 <- read.csv('../results/processed.csv')
  data3$algorithm[data3$algorithm == "c2d"] <- "\\textsc{c2d}"
  data3$algorithm[data3$algorithm == "cachet"] <- "\\textsc{Cachet}"
  data3$algorithm[data3$algorithm == "d4"] <- "\\textsc{d4}"
  data3$algorithm[data3$algorithm == "dpmc"] <- "\\textsc{DPMC}"
  data3$algorithm[data3$algorithm == "minic2d"] <- "\\textsc{miniC2D}"
  
  #ylimit <- max(fits$ub, data3$ub)
  #ylimit <- min(fits$lb, data3$lb)
  
  df <- data[data$repetitiveness == 0,] %>% group_by(algorithm, clause_factor)
  p1 <- plot_with_sd(df, "clause_factor", "$\\mu$") +
    geom_point()

  df <- data[data$clause_factor == 1.9,] %>% group_by(algorithm, treewidth)
  p3 <- plot_with_sd(df, "treewidth", "Primal treewidth") +
    geom_point() +
    rremove("ylab")
  
  p4 <- ggplot(fits, aes(clause_factor, fit, color = algorithm,
                         fill = algorithm, linetype = algorithm,
                         shape = algorithm)) +
    geom_line() +
    geom_point() +
    geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25, linetype = 0) +
    xlab("$\\mu$") +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    ylab("Base") +
    labs(color = "", fill = "", linetype = "") +
    scale_linetype_manual(values = c("twodash", "dotted", "dotdash", "solid",
                                     "longdash")) +
    ylim(0.99, 1.8) +
    rremove("xlab")

  p5 <- ggplot(data3, aes(mu, base, color = algorithm, fill = algorithm,
                          linetype = algorithm, shape = algorithm)) +
    geom_line() +
    geom_point() +
    geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25, linetype = 0) +
    xlab("$\\mu$") +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    ylab("Base") +
    labs(color = "", fill = "", linetype = "") +
    scale_linetype_manual(values = c("twodash", "dotted", "dotdash", "solid",
                                     "longdash")) +
    theme_set(theme_gray(base_size = 9)) +
    ylim(0.99, 1.8) +
    rremove("xlab") +
    rremove("ylab")
  
  figure <- ggarrange(p1, ggplot() + theme_void(), p3, ggplot() + theme_void(),
                      ggplot() + theme_void(), ggplot() + theme_void(),
                      p4, ggplot() + theme_void(), p5,
                      ncol = 3, nrow = 3, common.legend = TRUE,
                      legend = "right",
                      labels = c("$\\rho=0$", "","$\\mu=1.9$", "", "", "", "",
                                 "", ""),
                      widths = c(1, 0, 1), heights = c(1, -0.01, 1),
                      label.x = 0.1, label.y = 0.95)

  tikz(file = "../doc/kr/treewidth.tex", width = 6.5, height = 4.516875,
       standAlone = TRUE)
  annotate_figure(figure, bottom = text_grob("$\\mu$", size = 9))
  dev.off()
}
