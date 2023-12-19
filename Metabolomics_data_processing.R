library(tidyverse)

# Files available upon request.
mzm <- "MZM10_Data.csv" |> read_csv()

# ---- Check samples' sum Peak area distribution: ---- #

pl1 <- 
  mzm |> 
  select(-name, -roundMZ) |> 
  apply(2, sum) |> data.frame() |>
  ggplot(aes(.)) + 
  geom_histogram(color="black", fill = "navy") + 
  geom_vline(aes(xintercept = 4e8), color = "red") +
  theme_classic() +
  theme(plot.title = element_text(size = 6, hjust = 0.5)) +
  theme(axis.text.x = element_text(size = 6)) +
  theme(aspect.ratio = 1)
pl1

# ---- Filter samples with low sum Peak area: ---- #

sum_area_cutoff <- 4e8

sum_samples <- 
  mzm |> 
  select(-name,-roundMZ) |> 
  apply(2, sum)

mz_filtered_samples <- 
  mzm |> 
  select(name, roundMZ, which(sum_samples > (sum_area_cutoff)) + 2)

mz_excluded_samples <- 
  mzm |> 
  select(name, roundMZ, which(sum_samples <= (sum_area_cutoff)) + 2)

# ---- Normalization: ---- #
longmz <- mz_filtered_samples |> 
  pivot_longer(cols = contains("_")
             , names_to = "samples"
             , values_to = "peak_area")

normalized_longmz <- 
  longmz |> 
  group_by(samples) |> 
  mutate(sum = sum(peak_area)
       , RA = (peak_area / sum) * 100)

normalized_mz <- 
  normalized_longmz |> 
  pivot_wider(id_cols = c(name, roundMZ)
            , names_from = "samples"
            , values_from = "RA")

# ---- Filter metabolites with low prevalence: ---- #

metabolite_cutoff_n <- 0.0001

cocount_n <- apply((normalized_mz > metabolite_cutoff_n), 1, sum) 
  #counts in how many samples each metabolite was higher than the cutoff.

mzm_2filtered_n <- 
  normalized_mz |> 
  filter(cocount_n > (ncol(normalized_mz) - 2) * .25)
