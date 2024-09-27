rm(list = ls()) # clear environment
options(scipen = 999) # don't use scientific notation for very large or small numbers
today <- Sys.Date()
today <- format(today, format="%y%m%d")

# Load packages
## Create a list with needed libraries
pkgs <- c("here",
          "interactions",
          "egg",
          "lme4")

## Load each listed library, check if it's already installed
## and install if necessary
for (pkg in pkgs){
  if(!require(pkg, character.only = TRUE)){
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Load df and models from RData
## df for lmm: without outliers and without n-back tasks
load(here::here("Analysis/RData/lmm_df_all_subjects_09_24.RData")) 

## load model for ts1
m_RT_ts2_No_centering_age_random_slope_entropy <- readRDS(here::here("Analysis/RData/Mixed_models/m_RT_ts2_No_centering_age_random_slope_entropy.rds"))


# Run simple slope analysis
## CAVE: To calculate p values for mixed models (merMod objects), you need to have lmerTest and/or pbkrtest installed! Otherwise, sim_slopes will throw a rather unspecific error ("Requested column not found")
## Further documentation of this specifc dependency can be found in the help of summ.merMod {jtools}
ss_RT_ts2_noCentering_full_random_structure <- sim_slopes(m_RT_ts2_No_centering_age_random_slope_entropy, pred = surprisal_2_centered, modx = age, mod2 = cognitive_load, 
                                                          jnplot = T, data = lmm_df, sig.color = "#023FA5", insig.color = "#8E063B", 
                                                          control.fdr = T, mod.range = c(18,85), r.squared = F)
save(ss_RT_ts2_noCentering_full_random_structure, file = here::here(paste0("Analysis/RData/Mixed_models/simslopes_ts2_", today, "_2.RData")))

# # Plot simple slopes
# ## load individual plots into variables
# baseline <- ss_RT_ts1_noCentering_full_random_structure$jn[[1]]$plot
# one_back <- ss_RT_ts1_noCentering_full_random_structure$jn[[2]]$plot
# two_back <- ss_RT_ts1_noCentering_full_random_structure$jn[[3]]$plot
# 
# ## merge all plots together into one column
# simslopes_ts1 <- ggarrange(baseline +
#                              theme(legend.position = "none",
#                                    axis.title.x = element_blank(),
#                                    axis.ticks.x = element_blank(),
#                                    axis.text.x = element_blank(),
#                                    axis.title.y = element_blank()) +
#                              labs(title = NULL),
#                            one_back +
#                              theme(legend.position = "none",
#                                    axis.title.x = element_blank(),
#                                    axis.ticks.x = element_blank(),
#                                    axis.text.x = element_blank(),
#                                    axis.title.y = element_blank()) +
#                              labs(title = NULL),
#                            two_back +
#                              theme(legend.position = "none",
#                                    axis.title.x = element_blank(),
#                                    axis.title.y = element_blank()) +
#                              labs(title = NULL), 
#                            ncol = 1)
# ggsave(plot = simslopes_ts1, file = "test_ts1.pdf")

