# The goal of a model is to provide a simple low-dimensional summary of a dataset. 
# For hypothesis generation we focus on partition data into patterns and residuals
# In EDA models are compared with each other to see which works best through observation
# In Confirmatory Data Analysis previously formulated models are compared to the data (that was held out in the EDA).

# Two steps to modelling:

# 1. Define a family of models (e.g. y = a_1 * x + a_2, y = a_1 * x ^ a_2, or y = a_1 * a_2 ^ x, 
#    where x and y are known parts of the data and a_1 and a_2 are parameters).
# 2. Fitting of the model: find the model from the family that best describes your data (e.g. y = 3 * x + 7)

# All models are wrong, but some are useful. George Box

library(tidyverse)

library(modelr)
options(na.action = na.warn)

?sim1
ggplot(sim1, aes(x, y)) + 
  geom_point()

# y = a_0 + a_1 * x

models <- tibble(
  a1 = runif(250, -20, 40),
  a2 = runif(250, -5, 5)
)

ggplot(sim1, aes(x, y)) + 
  geom_abline(aes(intercept = a1, slope = a2), data = models, alpha = 1/4) +
  geom_point() 

?geom_abline

View(sim1)

model1 <- function(a, data) {
  a[1] + data$x * a[2]
}

model1(c(7, 1.5), sim1)
sim1$y - model1(c(7, 1.5), sim1)

# can we collapse it into one value?

# root-mean-squared deviation

measure_distance <- function(mod, data) {
  diff <- data$y - model1(mod, data)
  sqrt(mean(diff ^ 2))
}

measure_distance(c(7, 1.5), sim1)

# let's evaluate all the models above

# helper function to press generated variables into a vector of length 2
sim1_dist <- function(a1, a2) {
  measure_distance(c(a1, a2), sim1)
}

# we are using purrr to deal with managing input and output
models <- models %>% 
  mutate(dist = purrr::map2_dbl(a1, a2, sim1_dist))

# let's visualise
ggplot(sim1, aes(x, y)) + 
  geom_point(size = 2, colour = "grey30") + 
  geom_abline(
    aes(intercept = a1, slope = a2, colour = -dist), 
    data = filter(models, rank(dist) <= 10)
  )

# we do not necessarily see the data

ggplot(models, aes(a1, a2)) +
  geom_point(data = filter(models, rank(dist) <= 10), size = 4, colour = "red") +
  geom_point(aes(colour = -dist))

# is there a better way than just picking variables randomly?

# grid-search!

?expand.grid
View(expand.grid(a1 = seq(-5, 20, length = 25), a2 = seq(1, 3, length = 25)))

grid <- expand.grid(
  a1 = seq(-5, 20, length = 25),
  a2 = seq(1, 3, length = 25)) %>% 
  mutate(dist = purrr::map2_dbl(a1, a2, sim1_dist))

grid %>% 
  ggplot(aes(a1, a2)) +
  geom_point(data = filter(grid, rank(dist) <= 10), size = 4, colour = "red") +
  geom_point(aes(colour = -dist)) 

# looking at the best models vs. data

ggplot(sim1, aes(x, y)) + 
  geom_point(size = 2, colour = "grey30") + 
  geom_abline(
    aes(intercept = a1, slope = a2, colour = -dist), 
    data = filter(grid, rank(dist) <= 10)
  )

# you could manually make the grid finer and finer, but there is a better way

# Quasi-Newton search
best <- optim(c(0, 0), measure_distance, data = sim1, method = "BFGS")
best$par

# Nelder-Mead search 
best <- optim(c(0, 0), measure_distance, data = sim1)
best$par

# don't worry to much about optim now (you are not a stats expert), the intuition suffices
# anyway, let's visualise

ggplot(sim1, aes(x, y)) + 
  geom_point(size = 2, colour = "grey30") + 
  geom_abline(intercept = best$par[1], slope = best$par[2])

# optim can be used for everything you can write a distance function for

# special case linear model
# y = a_1 + a_2 * x_1 + a_3 * x_2 + ... + a_n * x_(n - 1)
?lm
# y ~ x is translated by lm to y = a_1 + a_2 * x
im1_mod <- lm(y ~ x, data = sim1)
sim1_mod <- lm(y ~ x, data = sim1)
coef(sim1_mod)
# lm is faster than optim but only works for linear models

# EXERCISE
# One downside of the linear model is that it is sensitive to unusual values because the distance incorporates a squared term. Fit a linear model to the simulated data below, and visualise the results. Rerun a few times to generate different simulated datasets. What do you notice about the model?

sim1a <- tibble(
  x = rep(1:10, each = 3),
  y = x * 1.5 + 6 + rt(length(x), df = 2)
)





# solution help
sim1a_mod <- lm(y ~ x, data = sim1a)
coef(sim1_mod)
ggplot(sim1a, aes(x, y)) + 
  geom_point(size = 2, colour = "grey30") + 
  geom_abline(intercept = coef(sim1a_mod)[1], slope = coef(sim1a_mod)[2])

?runif
?rt
tibble(
  x = seq(-5, 5, length.out = 100),
  normal = dnorm(x),
  student_t = dt(x, df = 2)
) %>%
  gather(distribution, density, -x) %>%
  ggplot(aes(x = x, y = density, colour = distribution)) +
  geom_line()

sim1a_loess <- loess(y ~ x, data = sim1a)
grid_loess <- sim1a %>%
  add_predictions(sim1a_loess)

ggplot(sim1a, aes(x, y)) + 
  geom_point(size = 2, colour = "grey30") + 
  geom_abline(intercept = coef(sim1a_mod)[1], slope = coef(sim1a_mod)[2], colour = "blue") +
  geom_line(aes(x = x, y = pred), data = grid_loess, colour = "red")

# Visualising models using predictions and residuals

grid <- sim1 %>% 
  data_grid(x) 
grid

grid <- grid %>% 
  add_predictions(sim1_mod) 
grid

# more complex than abline, but more general!
ggplot(sim1, aes(x)) +
  geom_point(aes(y = y)) +
  geom_line(aes(y = pred), data = grid, colour = "red", size = 1)

sim1 <- sim1 %>% 
  add_residuals(sim1_mod)
sim1

ggplot(sim1, aes(resid)) + 
  geom_freqpoly(binwidth = 0.5)


ggplot(sim1, aes(x, resid)) + 
  geom_ref_line(h = 0) +
  geom_point() 

# EXERCISE
# Instead of using lm() to fit a straight line, you can use loess() to fit a smooth curve. Repeat the process of model fitting, grid generation, predictions, and visualisation on sim1 using loess() instead of lm(). How does the result compare to geom_smooth()