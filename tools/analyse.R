library(plyr)
library(dplyr)
library(ggplot2)
library(maditr)
library(Hmisc)
library(tikzDevice)
library(ggpubr)
library(ggthemes)

TIMEOUT <- 500
IQR1 <- 0.25
IQR2 <- 0.75

# data <- read.csv("../results.csv")
# data <- read.csv("../experiments/regular2/results.csv")

read_data <- function(filename) {
  data <- read.csv(filename)
  # What proportion of instances run out of memory?
  print("ran out of memory")
  print("overall")
  overall <- sum(is.na(data$answer) & data$time < TIMEOUT) / nrow(data)
  print(overall)
  print("cachet")
  print(sum(data$algorithm == "cachet" & is.na(data$answer) & data$time < TIMEOUT) / nrow(data) / overall)
  print("c2d")
  print(sum(data$algorithm == "c2d" & is.na(data$answer) & data$time < TIMEOUT) / nrow(data) / overall)
  print("d4")
  print(sum(data$algorithm == "d4" & is.na(data$answer) & data$time < TIMEOUT) / nrow(data) / overall)
  print("dpmc")
  print(sum(data$algorithm == "dpmc" & is.na(data$answer) & data$time < TIMEOUT) / nrow(data) / overall)
  print("minic2d")
  print(sum(data$algorithm == "minic2d" & is.na(data$answer) & data$time < TIMEOUT) / nrow(data) / overall)
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

# ==================== Plots ====================

plot_with_sd <- function(df, x_value, x_label) {
  df <- df %>% summarise(mean = median(time),
                         lb = unname(quantile(time, IQR1)),
                         ub = unname(quantile(time, IQR2)))
  ggplot(df, aes(.data[[x_value]], mean, group = algorithm, colour = algorithm,
                 fill = algorithm, linetype = algorithm)) +
    geom_line() +
    geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25, linetype = 0) +
    xlab(x_label) +
    ylab("Time (s)") +
    labs(color = "", fill = "", linetype = "") +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    scale_linetype_manual(values = c("twodash", "dotted", "dotdash", "solid", "longdash"))
}
fit_model <- function(algorithm, clause_factor) {
#  df <- data[data$algorithm == algorithm & data$clause_factor == clause_factor,]
  df <- data[data$algorithm == algorithm & data$clause_factor == clause_factor,] %>%
    group_by(treewidth) %>% summarise(time = median(time))
  model <- lm(log(df$time) ~ df$treewidth)
  sum <- summary(model)
  print(sum)
  return(c(sum$coefficients[2, 1], sum$coefficients[2, 2], sum$r.squared))
}

# First round: density & treewidth
#data <- read_data("../results.csv")
data <- read_data("../experiments/regular1/results.csv")
data <- read_data("../experiments/regular2/results.csv")
data <- read_data("../experiments/regular3/results.csv")
df <- data[data$repetitiveness == 0,] %>% group_by(algorithm, clause_factor)
p1 <- plot_with_sd(df, "clause_factor", "$\\mu$") +
  geom_vline(xintercept = 1.3, linetype = "dashed") +
  geom_vline(xintercept = 1.9, linetype = "dashed")
df <- data[data$clause_factor == 1.3,] %>% group_by(algorithm, treewidth)
p2 <- plot_with_sd(df, "treewidth", "Primal treewidth")
df <- data[data$clause_factor == 1.9,] %>% group_by(algorithm, treewidth)
p3 <- plot_with_sd(df, "treewidth", "Primal treewidth")
fits <- expand.grid(sort(unique(data$algorithm)), unique(data$clause_factor))
names(fits) <- c("algorithm", "clause_factor")
results <- mapply(fit_model, fits$algorithm, fits$clause_factor)
fits$fit <- exp(results[1,])
fits$lb <- exp(results[1,] - results[2,])
fits$ub <- exp(results[1,] + results[2,])
p4 <- ggplot(fits, aes(clause_factor, fit, color = algorithm, fill = algorithm, linetype=algorithm)) +
  geom_line() +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25, linetype = 0) +
  xlab("$\\mu$") +
  scale_color_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  ylab("$e^\\alpha$") +
  labs(color = "", fill = "", linetype = "") +
  scale_linetype_manual(values = c("twodash", "dotted", "dotdash", "solid", "longdash"))

tikz(file = "../paper/treewidth.tex", width = 6.5, height = 2.4375, standAlone = TRUE)
ggarrange(p1, p4, p2, p3, common.legend = TRUE, legend = "right",
          labels = c("$\\rho=0$", "", "$\\mu=1.3$", "$\\mu=1.9$"),
          label.x = 0.1, label.y = 0.95)
dev.off()

# R^2
r2table <- cbind(fits, r2 = results[3,])
r2table$r2[r2table$algorithm == "\\textsc{d4}" & r2table$clause_factor == 4.3] <- 1
r2table$clause_factor <- as.factor(r2table$clause_factor)
tikz(file = "../paper/r2.tex", width = 3, height = 3, standAlone = TRUE)
ggplot(r2table, aes(algorithm, clause_factor, fill = r2)) + geom_tile() +
  geom_text(aes(label = round(r2, 2))) +
  xlab(NULL) +
  ylab("$\\mu$") +
  scale_fill_distiller(palette = "Purples",
                       guide = guide_colorbar(direction = "horizontal")) +
  labs(fill = "$R^2$") +
  theme(legend.position = "bottom",
        legend.margin = margin(t = 0, unit = 'cm'))
dev.off()

# For manually digging through the numbers
df <- df %>% summarise(mean = median(time), lb = unname(quantile(time, IQR1)), ub = unname(quantile(time, IQR2)))
max(fits$fit[fits$algorithm == "\\textsc{DPMC}"])
max(fits$fit[fits$algorithm == "\\textsc{c2d}"])
fit_model("\\textsc{d4}", 4.3)

# Second round: delta & epsilon
data <- read_data("../experiments/regular2/results.csv")
df <- data %>% group_by(algorithm, prop_deterministic)
p1 <- plot_with_sd(df, "prop_deterministic", "$\\delta$")
data <- read_data("../experiments/regular3/results.csv")
df <- data %>% group_by(algorithm, prop_equal)
p2 <- plot_with_sd(df, "prop_equal", "$\\epsilon$")
tikz(file = "../paper/delta_epsilon.tex", width = 6.5, height = 1.2, standAlone = TRUE)
ggarrange(p1, p2, common.legend = TRUE, legend = "right")
dev.off()

# ==================== EXTRA STUFF ====================

# Scalability data
data1 <- read.csv("../experiments/scalability/irregular.csv")
data1$type <- "non-$k$-CNF"
data2 <- read.csv("../experiments/scalability/regular.csv")
data2$type <- "$k$-CNF"
data <- rbind(data1, data2)
data$algorithm[data$algorithm == "c2d"] <- "\\textsc{c2d}"
data$algorithm[data$algorithm == "cachet"] <- "\\textsc{Cachet}"
data$algorithm[data$algorithm == "d4"] <- "\\textsc{d4}"
data$algorithm[data$algorithm == "dpmc"] <- "\\textsc{DPMC}"
data$algorithm[data$algorithm == "minic2d"] <- "\\textsc{miniC2D}"
tikz(file = "../paper/scalability.tex", width = 6.5, height = 2.4375)
ggplot(data, aes(num_variables, time, color = algorithm, linetype = algorithm)) +
  geom_smooth() +
  xlab("$\\nu$") +
  ylab("Time (s)") +
  labs(color = "Algorithm", linetype = "Algorithm") +
  facet_wrap(~ type, scales = "free") +
  scale_color_brewer(palette = "Dark2")
dev.off()

# Check answers
answers <- data %>% dcast(instance ~ algorithm, value.var = "answer")
proportion <- function(algorithm1, algorithm2) {
  differences <- !is.na(answers[[algorithm1]]) & !is.na(answers[[algorithm2]]) & abs(answers[[algorithm1]] - answers[[algorithm2]]) <=
    pmax(0.01, 0.01 * pmin(answers[[algorithm1]], answers[[algorithm2]]))
  differences2 <- !is.na(answers[[algorithm1]]) & !is.na(answers[[algorithm2]])
  return(c(sum(differences), sum(differences2)))
}
correctness <- expand.grid(algorithm1 = sort(unique(data$algorithm)), algorithm2 = sort(unique(data$algorithm)))
correctness$algorithm1 <- as.character(correctness$algorithm1)
correctness$algorithm2 <- as.character(correctness$algorithm2)
correctness <- mdply(correctness, proportion)
correctness$V1 <- correctness$V1 / correctness$V2
ggplot(correctness, aes(algorithm1, algorithm2)) +
  geom_tile(aes(fill = V1)) +
  geom_text(aes(label = round(V1, 1)))

# Correlations
correlation_data <- data[, c("repetitiveness", "prop_deterministic",
                             "literal_factor", "clause_factor", "treewidth", "prop_equal", "time")]
cor(correlation_data)
rcorr(as.matrix(correlation_data))

# Count missing instances
counts <- data %>% count(algorithm, clause_factor, repetitiveness)
counts <- data %>% count(algorithm, prop_deterministic, prop_equal)
