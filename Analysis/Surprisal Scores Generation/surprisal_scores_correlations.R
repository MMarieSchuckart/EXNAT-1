# Determine which surprisal score chunk sizes we should use

# Author: Merle Schuckart (merle.schuckart@gmx.de)
# Version: February 2023

################################################################################


# -------- 0. Settings --------

# Turn off scientific notation
options(scipen = 999)

# Clear environment
remove(list = ls())

# Create a list with needed libraries

pkgs <- c("rstudioapi", # for getting path to this file 
          "gtools", # for getting tuples from list
          "Hmisc")

# Load each listed library, check if it's already installed 
# and install if necessary
for (pkg in pkgs){
  if(!require(pkg, character.only = TRUE)){
    install.packages(pkg)
    library(pkg, character.only = TRUE)      
  }
}

# Set working directory:
# get path of this file
current_path = rstudioapi::getActiveDocumentContext()$path 
# set it as our wd
setwd(dirname(current_path))
# print it just to make sure it's correct:
print(getwd())

# everything's ready, so remove helper variables from environment
rm(pkg, pkgs, current_path)


# -------- 1. get surprisal scores --------

# read in csv with all surprisal scores:
#surprisal_df <- read.csv("surprisal_and_similarity_scores.csv") # surprisal scores for different context chunk sizes
#surprisal_df <- read.csv("surprisal_scores_lesioned_layers.csv") # surprisal scores from the lesioned layers with context chunk size always 50 words
surprisal_df <- read.csv("surprisal_scores_masked_context.csv") # surprisal scores for different context chunk sizes with masked redundant input

# only rows with 1 surprisal score in each column (aka remove rows with NAs)
surprisal_scores_df <- subset(surprisal_df, !is.na(surprisal_60)) # for # surprisal scores for different context chunk sizes


# -------- 2. compute correlation between surprisal scores for different chunk sizes --------

# get idx of all column names containing surprisal scores:
idx_surprisal_rows <- which(grepl("surprisal", names(surprisal_scores_df), fixed = TRUE))

# get all possible combination of column indices:
tuples <- as.data.frame(t(combn(idx_surprisal_rows, 2)))

for (row_idx in 1:length(tuples$V1)){
  
  # get columns with suprisal scores from surprisal_scores_df by 
  # using the two indices from tuples
  x_name <-  names(surprisal_scores_df[tuples[row_idx, 1]])
  x <- unname(unlist(surprisal_scores_df[tuples[row_idx, 1]]))

  y_name <-  names(surprisal_scores_df[tuples[row_idx, 2]])
  y <- unname(unlist(surprisal_scores_df[tuples[row_idx, 2]]))
  
  # Check distribution of surprisal scores using Shapiro-Wilk tests.
  # If at least one of them is significant (aka the data are not normally distributed),
  # use non-parametric correlation test (= Spearman)
  if (shapiro.test(x)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
    corr_method <- "spearman"
  } else {
    corr_method <- "pearson"
    message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
  }
  
  # compute correlation between the distributions:
  cor <-  round(cor(x, y, method = corr_method), digits = 3)
  
  # print correlation to console
  message(paste("Correlation (", corr_method, ") between ", x_name, 
                " & ", y_name, ": ", as.character(cor), sep = "") )
}





#==============================================================================

### Correlation between Surprisal Scores & Word Frequencies

# -------- 1. get surprisal scores & word frequencies --------

# read in word frequency df:
word_freqs_df <- read.csv("../word frequencies/Word_freqs.csv", sep = ";")
# get the full surprisal score df again:
surprisal_df <- read.csv("surprisal_scores_masked_context.csv") # surprisal scores for different context chunk sizes with masked redundant input

# bind them together:
word_freqs_df <- cbind(surprisal_df, word_freqs_df$word_frequency)

# only use rows with 1 surprisal score in each column (aka remove rows with NAs)
word_freqs_df <- subset(word_freqs_df, !is.na(surprisal_60)) # for # surprisal scores for different context chunk sizes


# -------- 2. compute correlation between surprisal scores for different chunk sizes --------

# get idx of all column names containing surprisal scores & word frequencies:
idx_surprisal_rows <- which(grepl("surprisal", names(word_freqs_df), fixed = TRUE))

# get all possible combination of column indices:
for (row_idx in idx_surprisal_rows){
  
  # get column with suprisal scores from surprisal_scores_df
  x_name <- names(word_freqs_df[row_idx])
  x <- word_freqs_df[row_idx]
  x <- unname(unlist(x))
  # get word frequency column
  y_name <- "word_frequency"
  y <- unname(unlist(word_freqs_df[length(word_freqs_df)]))

  # Check distribution of surprisal scores using Shapiro-Wilk tests.
  # If at least one of them is significant (aka the data are not normally distributed),
  # use non-parametric correlation test (= Spearman)
  if (shapiro.test(x)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
    corr_method <- "spearman"
  } else {
    corr_method <- "pearson"
    message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
  }
  
  # compute correlation between the distributions:
  cor <-  round(cor(x, y, method = corr_method), digits = 3)
  
  # print correlation to console
  message(paste("Correlation (", corr_method, ") between ", x_name, 
                " & ", y_name, ": ", as.character(cor), sep = "") )
}

# weak negative relationship between surprisal on different time scales and word frequency.
# It makes sense that it's a negative relationship, as low-frequency words probably have 
# high surprisal scores, but I'm surprised the correlation is so weak. 
# Maybe that's due to the masking.


#==============================================================================

### Correlation of Word Frequency and Word Length

# get word length for single words (without punctuation)
word_length_single <- nchar(word_freqs_df$word_no_punct)
x_name <- "word length"

y <- unname(unlist(word_freqs_df[length(word_freqs_df)]))
y_name <- "word frequency"
  
# Check distribution of surprisal scores using Shapiro-Wilk tests.
# If at least one of them is significant (aka the data are not normally distributed),
# use non-parametric correlation test (= Spearman)
if (shapiro.test(word_length_single)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
  corr_method <- "spearman"
} else {
  corr_method <- "pearson"
  message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
}

# compute correlation between the distributions:
cor <-  round(cor(x, y, method = corr_method), digits = 3)

# print correlation to console
message(paste("Correlation (", corr_method, ") between ", x_name, 
              " & ", y_name, ": ", as.character(cor), sep = "") )


#==============================================================================

### Correlations of Surprisal Scores and Word Length

# create df with surprisal scores and word lengths
word_length_single <- nchar(surprisal_df$word_no_punct)
word_lengths_surprisal_df <- cbind(surprisal_df, word_length_single)

# only use rows with 1 surprisal score in each column (aka remove rows with NAs)
word_lengths_surprisal_df <- subset(word_lengths_surprisal_df, !is.na(surprisal_60))

# get idx of all column names containing surprisal scores:
idx_surprisal_rows <- which(grepl("surprisal", names(word_lengths_surprisal_df), fixed = TRUE))

# get all possible combination of column indices:
for (row_idx in idx_surprisal_rows){
  
  # get column with suprisal scores from surprisal_scores_df
  x_name <- names(word_lengths_surprisal_df[row_idx])
  x <- word_freqs_df[row_idx]
  x <- unname(unlist(x))
  # get word frequency column
  y_name <- "word_length_single"
  y <- unname(unlist(word_lengths_surprisal_df[length(word_lengths_surprisal_df)]))
  
  # Check distribution of surprisal scores using Shapiro-Wilk tests.
  # If at least one of them is significant (aka the data are not normally distributed),
  # use non-parametric correlation test (= Spearman)
  if (shapiro.test(x)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
    corr_method <- "spearman"
  } else {
    corr_method <- "pearson"
    message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
  }
  
  # compute correlation between the distributions:
  cor <-  round(cor(x, y, method = corr_method), digits = 3)
  
  # print correlation to console
  message(paste("Correlation (", corr_method, ") between ", x_name, 
                " & ", y_name, ": ", as.character(cor), sep = "") )
}

# weak negative relationship between surprisal on different time scales and word frequency.
# It makes sense that it's a negative relationship, as low-frequency words probably have 
# high surprisal scores, but I'm surprised the correlation is so weak. 
# Maybe that's due to the masking.


#==============================================================================

### Correlations of Surprisal Scores of Current and Previous Word

# create columns with surprisal for previous word: 

#Get all columns that start with "surprisal_"
surprisal_prev_df <- surprisal_df[, grep("^surprisal_", colnames(surprisal_df))]

# append 1 row with NAs and dump the last row to "shift" the surprisal scores to the next row
surprisal_prev_df <- rbind(NA, surprisal_prev_df[-nrow(surprisal_prev_df), ])

# change column names to "prev_surprisal_" + TS
colnames(surprisal_prev_df) <- paste("prev_", colnames(surprisal_prev_df), sep = "")

# append as new columns to surprisal_df
surprisal_df <- cbind(surprisal_df, surprisal_prev_df)

# only use rows with 1 surprisal score in each column (aka remove rows with NAs)
na_rows <- apply(surprisal_df, 1, function(row) any(is.na(row)))
surprisal_df <- surprisal_df[!na_rows, ]


# Compute Correlations:
# Doesn't really make a lot of sense to compute the correlation of TS1 and TS60prev 
# for example, but I'll do it anyway just for good measure.


# get idx of all column names containing surprisal scores & word frequencies:
idx_surprisal_rows <- which(grepl("surprisal", names(surprisal_df), fixed = TRUE))

# get all possible combination of column indices:
tuples <- as.data.frame(t(combn(idx_surprisal_rows, 2)))

for (row_idx in 1:length(tuples$V1)){
  
  # get columns with suprisal scores from surprisal_scores_df by 
  # using the two indices from tuples
  x_name <-  names(surprisal_df[tuples[row_idx, 1]])
  x <- unname(unlist(surprisal_df[tuples[row_idx, 1]]))
  
  y_name <-  names(surprisal_df[tuples[row_idx, 2]])
  y <- unname(unlist(surprisal_df[tuples[row_idx, 2]]))

  # Check distribution of surprisal scores using Shapiro-Wilk tests.
  # If at least one of them is significant (aka the data are not normally distributed),
  # use non-parametric correlation test (= Spearman)
  if (shapiro.test(x)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
    corr_method <- "spearman"
  } else {
    corr_method <- "pearson"
    message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
  }
  
  # compute correlation between the distributions:
  cor <-  round(cor(x, y, method = corr_method), digits = 3)
  
  # print correlation to console
  message(paste("Correlation (", corr_method, ") between ", x_name, 
                " & ", y_name, ": ", as.character(cor), sep = "") )
}

# weak negative relationship between surprisal on different time scales and word frequency.
# It makes sense that it's a negative relationship, as low-frequency words probably have 
# high surprisal scores, but I'm surprised the correlation is so weak. 
# Maybe that's due to the masking.







#==============================================================================

# OLD: 

# Do the same again, but this time for the orthogonalised surprisal 
# scores on time scales 1, 2, 8, 16 and 32
# This is just to make sure the orthogonalisation worked.
# After the orthogonalization, the surprisal scores on different TS 
# shouldn't be correlated anymore. 

# 
# # -------- 1. get orthogonalised surprisal scores --------
# 
# # Use the file with all surprisal scores from before.
# # Get only rows with 1 surprisal score in each column (aka remove rows with NAs, 
# # but unlike before where we looked at all time scales, this time the highest 
# # possible TS is 32)
# ortho_surprisal_df <- subset(surprisal_df, !is.na(surprisal_32_ortho))
# 
# # -------- 2. compute correlation between orthogonalised surprisal scores for different chunk sizes --------
# 
# # only get columns with orthogonalised surprisal scores for TS 1, 2, 8, 16 and 32:
# ortho_surprisal_df <- ortho_surprisal_df[, c("surprisal_1_ortho", "surprisal_2_ortho", 
#                                              "surprisal_8_ortho", "surprisal_16_ortho", 
#                                              "surprisal_32_ortho")]
# 
# # get all possible combination of column names:
# tuples <- as.data.frame(t(combn(names(ortho_surprisal_df), 2)))
# 
# # loop column name tuples
# for (tuple_idx in 1:length(tuples$V1)){
# 
#   # get columns with suprisal scores from surprisal_scores_df by 
#   # using the two indices from tuples
#   x_name <-  names(surprisal_scores_df[tuples[tuple_idx, 1]])
#   x      <- unname(unlist(surprisal_scores_df[tuples[tuple_idx, 1]]))
#   
#   y_name <-  names(surprisal_scores_df[tuples[tuple_idx, 2]])
#   y      <- unname(unlist(surprisal_scores_df[tuples[tuple_idx, 2]]))
#   
#   # Check distribution of surprisal scores using Shapiro-Wilk tests.
#   # If at least one of them is significant (aka the data are not normally distributed),
#   # use non-parametric correlation test (= Spearman)
#   if (shapiro.test(x)$p.value <= 0.05 | shapiro.test(y)$p.value <= 0.05){
#     corr_method <- "spearman"
#   } else {
#     corr_method <- "pearson"
#     message(paste("Careful, using parametric test here. Please check linearity of distributions", x_name, "and", y_name, "visually.", sep = " "))
#   }
#   
#   # compute correlation between the distributions:
#   cor    <-  round(cor(x, y, method = corr_method), digits = 3)
#   
#   # print correlation to console
#   message(paste("Correlation (", corr_method, ") between ", x_name, 
#                 " & ", y_name, ": ", as.character(cor), sep = "") )
# }
# # Looks fine to me! 











