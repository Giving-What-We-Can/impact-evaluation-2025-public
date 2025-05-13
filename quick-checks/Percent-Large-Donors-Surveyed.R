

pacman::p_load(tidyverse, dbplyr, gt)


source("connect-parfit.R")

pledge_donations_2023_by_pledger <- tbl(
  con, dbplyr::in_schema("reporting", "complete_giving_report")
) %>% 
  filter(year(donation_date) == 2023,
         !is.na(pledge_id)) %>% 
  # Get total usd-normalised recorded 2023 donations by pledger
  summarise(recorded_2023 = sum(amount_normalized), .by = pledge_id)


make_to_combine <- function(tbl_con){
  tbl_con %>% 
    mutate(pledge_id = as.double(pledge_id)) %>% 
    select(pledge_id) %>% 
    collect()
}

surveyed <- 
  bind_rows(
    make_to_combine(tbl(con, in_schema("impact_surveys", "pcv2023_sample"))),
    make_to_combine(tbl(con, in_schema("impact_surveys", "prac2023_sample"))),
    make_to_combine(tbl(con, in_schema("impact_surveys", "mpcv2025_sample")))
  ) %>% 
  mutate(surveyed = T)


eligible_pledgers_with_2023_quintiles <- tbl(
  con, in_schema("pledges", "verified_active_pledge")
) %>% 
  filter(
    pledge_type == "giving_what_we_can",  # 10% Pledge
    year(created_at) <= 2022, # Created before start_year
    between(year(lower(period)), 2009, 2022) # Pledge started before year
  ) %>%   
  select(pledge_id = id, person_id) %>% 
  # Join 2023 recorded donations
  left_join(pledge_donations_2023_by_pledger, by = join_by(pledge_id)) %>% 
  # Set those with no recorded donations to 0
  mutate(recorded_2023 = coalesce(recorded_2023, 0),
         pledge_id = as.double(pledge_id)) %>% 
  collect() %>% 
  # GET QUINTILES
  # Arrange in descending order of total donations
  arrange(desc(recorded_2023)) %>%
  mutate(
    cum_share = cumsum(recorded_2023) / sum(recorded_2023),
    value_quintile = case_when(
      cum_share <= 0.2 ~ 1,
      cum_share <= 0.4 ~ 2,
      cum_share <= 0.6 ~ 3,
      cum_share <= 0.8 ~ 4,
      TRUE ~ 5
    )
  ) %>% 
  left_join(surveyed)



eligible_pledgers_with_2023_quintiles %>% 
  mutate(
    surveyed = coalesce(surveyed, F),
    row = row_number(), num_surveyed = cumsum(surveyed)) %>% 
  filter(row != num_surveyed)

eligible_pledgers_with_2023_quintiles %>% 
  mutate(
    surveyed = coalesce(surveyed, F)) %>% 
  slice_head(n = 1000) %>% 
  summarise(sum(surveyed)/n())

