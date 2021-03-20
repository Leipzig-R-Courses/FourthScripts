library(tidyverse)


# Longer ------------------------------------------------------------------

# What might be tricky here?
table4a

table4a %>% pivot_longer(2:3)
table4a %>% pivot_longer(2:3, names_to = "year", values_to = "cases")

# similar here
table4b
table4b %>% pivot_longer(2:3, names_to = "year", values_to = "population")

# we can bring it together
left_join(table4a %>% pivot_longer(2:3, names_to = "year", values_to = "cases"), 
          table4b %>% pivot_longer(2:3, names_to = "year", values_to = "population"))

# bigger example

relig_income

relig_income %>% 
  pivot_longer(!religion, names_to = "income", values_to = "count")

# more complex

billboard

billboard %>% 
  pivot_longer(
    cols = starts_with("wk"), 
    names_to = "week", 
    names_prefix = "wk",
    names_transform = list(week = as.integer),
    values_to = "rank",
    values_drop_na = TRUE
  )

# Wider -------------------------------------------------------------------

table2
table2 %>%
  pivot_wider(names_from = type, values_from = count)

tibble(
  year   = c(2015, 2015, 2016, 2016),
  half  = c(   1,    2,     1,    2),
  return = c(1.88, 0.59, 0.92, 0.17)
) %>% 
  pivot_wider(names_from = year, values_from = return) %>% 
  pivot_longer(`2015`:`2016`, names_to = "year", values_to = "return")


# Exercise ----------------------------------------------------------------

# 1. Why does this code fail?

table4a %>% 
  pivot_longer(c(1999, 2000), names_to = "year", values_to = "cases")

# 2. What would happen if you widen this table? Why? 
#    How could you add a new column to uniquely identify each value?

people <- tribble(
  ~name,             ~names,  ~values,
  #-----------------|--------|------
  "Phillip Woods",   "age",       45,
  "Phillip Woods",   "height",   186,
  "Phillip Woods",   "age",       50,
  "Jessica Cordero", "age",       37,
  "Jessica Cordero", "height",   156
)


# separate ----------------------------------------------------------------

table3
table3 %>% 
  separate(rate, into = c("cases", "population"))

# but look at the types!

table3 %>% 
  separate(rate, into = c("cases", "population"), convert = TRUE)

# alternative

table3 %>% 
  separate(year, into = c("century", "year"), sep = 2)

table3 %>% 
  separate(year, into = c("century", "year"), sep = 2) -> test

test
test %>% unite(combined,century,year,sep = "")
