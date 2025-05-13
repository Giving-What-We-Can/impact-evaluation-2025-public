

pacman::p_load(tidyverse, dbplyr, gt)


source("connect-parfit.R")


tbl(con, in_schema("reporting", "complete_giving_report")) %>% 
  mutate(donation_year = year(donation_date)) %>% 
  filter(object_type == "payment",
         is.na(pledge_id),
         between(donation_year,2020,2024)
         ) %>% 
  # Join inflation adjustments and apply to USD normalised donations
  left_join(  
    tbl(con, in_schema("impact_surveys","inflation_data")),
    join_by(donation_year == year)
    ) %>% 
  mutate(
    amount_adj_norm = amount_normalized * cumulative_inflation_to_2024,
    period = case_when(
      between(donation_year,2020,2022) ~ "2020-2022",
      between(donation_year,2023,2024) ~ "2023-2024"
    )
    ) %>% 
  summarise(
    total_recorded_unadjusted = sum(amount_normalized),
    total_recorded = sum(amount_adj_norm), 
    duration = n_distinct(donation_year),
    .by = period
  ) %>% 
  mutate(average_recorded = total_recorded/duration)



tbl(con, in_schema("reporting", "complete_giving_report")) %>% 
  mutate(donation_year = year(donation_date)) %>% 
  filter(object_type == "payment",
         is.na(pledge_id),
         between(donation_year,2020,2024)
  ) %>% 
  # Join inflation adjustments and apply to USD normalised donations
  left_join(  
    tbl(con, in_schema("impact_surveys","inflation_data")),
    join_by(donation_year == year)
  ) %>% 
  mutate(
    amount_adj_norm = amount_normalized * cumulative_inflation_to_2024,
    period = case_when(
      between(donation_year,2020,2022) ~ "2020-2022",
      between(donation_year,2023,2024) ~ "2023-2024"
    )
  ) %>% 
  summarise(
    annual_recorded = sum(amount_adj_norm),
    .by = c(donation_year,person_id,period)
  ) %>% 
  mutate(above_threshold = annual_recorded>140e3) %>% 
  summarise(n = n(), total = sum(annual_recorded), .by = c(period, above_threshold))
