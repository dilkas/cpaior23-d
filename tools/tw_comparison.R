df <- read.csv("../results/tw_comparison.csv")
plot(df$exact, df$approximate - df$exact)
t <- table(df$approximate - df$exact)
(t[1] + t[2] + t[3])/sum(t)
