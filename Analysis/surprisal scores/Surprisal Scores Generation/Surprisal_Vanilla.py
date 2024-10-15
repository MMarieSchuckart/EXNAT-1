#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep 10 12:21:03 2024

@author: merle
"""

""" Generate vanilla surprisal scores using an input length of 2 words """




















# If you want to get surprisal scores, uncomment the surprisal 
# calculations in the functions and change names in the last big loop 
# to surprisal instead of entropy. This currently gives you only entropy values.



""" Settings """
import math # for mathematical functions
import numpy as np # also for mathematical functions
import pandas as pd # for dfs
import csv # for reading in csv properly
import random
import re # for regex
import warnings # for turning off warnings for a moment

import tensorflow as tf
# use AutoModelForCausalLM instead of AutoModelWithLMHead because AutoModelWithLMHead will be deprecated soon-ish?
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch


# import csv with texts

# read in csv with texts
texts_df = pd.read_csv('/Users/merle/GitHub/PhD/EXNAT/Onlinestudy_EXNAT-1/Analysis/surprisal scores/Surprisal Scores Generation/Texts_surprisal_scores.csv',
                       sep = ";",
                       quoting = csv.QUOTE_NONE,
                       quotechar = None)
# get unique text numbers in texts_df
text_nrs = list(set(texts_df["text_nr"]))
print(text_nrs)



""" Load and costumize model """
# (disable %%capture to print output in console)

# download pre-trained German GPT-2 model & tokenizer from the Hugging Face model hub
tokenizer = AutoTokenizer.from_pretrained("dbmdz/german-gpt2")

# initialise the model, use end-of-sequence (EOS) token as padding tokens
model = AutoModelForCausalLM.from_pretrained("dbmdz/german-gpt2", pad_token_id = tokenizer.eos_token_id)



""" Function: Generate Surprisal Score & Entropy for a Given Actual Next Word and Context Chunk """

def vanilla_next_word_surprisal_entropy(previous_words, actual_word, model):

    #print("Vanilla surprisal score and entropy for input text:")

    seed = 42
    torch.manual_seed(seed)
    np.random.seed(seed)

    # generate token ids for each of the x previous words
    encoded_input = tokenizer(" ".join(previous_words),
                              add_special_tokens = False,
                              return_tensors = "pt")

    # get token IDs, put them in a list and in a tensor
    ids_tensor = encoded_input['input_ids']
    ids_list = ids_tensor[0].tolist()
    #print("input IDs:", ids_list)

    # also tokenize the actual next word
    act_word_id = tokenizer.encode(actual_word)

    """ loop IDs of current word """
    curr_id_probs = []
    curr_token_entropies = []
    for curr_id in act_word_id:

          #print("computing probability for ID " +  str(curr_id) + " of word " + actual_word)
          # generate probabilities for each possible token being the actual next token
          # --> use modified attention mask:
          output = model.generate(ids_tensor,
                                  return_dict_in_generate = True,
                                  output_scores = True,
                                  max_new_tokens = 1) # set output length here - 1 because I only want 1 token

          """ Calculate Token-Level Next-Word Probability """
          # read out probabilities for all IDs
          logits = output.scores[0] # logits = probabilities with range [0,1] transformed to range [inf, -inf]
          probs = tf.nn.softmax(logits) # transform logits back to probabilities

          # get probability for actual ID being the next one & append it to
          # array with probabilities of all IDs for current word
          curr_id_probs.append(probs.numpy()[0][curr_id])

          # append current token ID to list of previous words (if there are any)
          # reason: The previous parts of the word are part of the context.
          ids_list = ids_list + [curr_id]
          ids_tensor = torch.tensor(ids_list).unsqueeze(0) # put the token IDs into a tensor


          """ Calculate Token-Level Entropy """
          # Entropy = probabilities for next word given context 
          # For each possible next word in the vocabulary, multiply its probability with its log probability. 
          # This gives us a weighted measure of surprise for each word, where more likely words contribute 
          # less to the total than less likely words.
          # Sum this product over all possible next words in the vocabulary. This sum gives us the total 
          # expected surprise or uncertainty for the next word prediction.
        
          # log-transform probabilities
          log_probs = tf.math.log(probs)

          # calculate entropy (- sum of probabilities * log probabilities)
          curr_entropy = -tf.reduce_sum(probs * log_probs)
          # convert entropy tensor to numpy array and get value
          curr_entropy = curr_entropy.numpy().item()
          #print("current token entropy:", curr_entropy)
          curr_token_entropies.append(curr_entropy)


    """ Generate Word-Level Surprisal Score """
    # multiply all probabilities for current word:
    act_word_prob = np.prod(curr_id_probs)

    # transform probability value into surprisal score (negative log of the probability)
    # negative log = log(1 / x) with x being the value you want to get the negative log of.
    # I use e as a base value for the log here.
    surprisal_score = np.log( 1 / act_word_prob )

    # if surprisal score == Inf, set surprisal score to 100
    if surprisal_score == float('inf'):
        surprisal_score = 100

    """ Generate Word-Level Entropy """
    # get mean of all entropy values for current word:
    curr_word_entropy = np.mean(curr_token_entropies)
    
    """  Return Surprisal Score and Entropy """
    print("current word surprisal:", surprisal_score)
    print("current word entropy:", curr_word_entropy)
    return(surprisal_score, curr_word_entropy)


# Test case: Compute surprisal for text with some words at the start of the chunk being masked
print(vanilla_next_word_surprisal_entropy(previous_words = "Virginia Stephen besuchte keine Schule, sondern erhielt von Hauslehrern und ihrem Vater Privatunterricht. Sie war beeindruckt von der schriftstellerischen Arbeit ihres", actual_word = "Vaters", model = model))




""" Compute Surprisal Scores & Entropies for all Texts """

# Suppress warnings for this script
warnings.filterwarnings("ignore")

n_context_words = 2 # always use past 2 words as context for prediction

# add 2 columns to texts_df for surprisal scores and entropies
texts_df['surprisal_2_words_context'] = None
texts_df['entropy_2_words_context'] = None

# loop words in texts
for word_idx, word in enumerate(texts_df["word_punct"]):

    # check if we have enough context in the current text. If so, go on with the prediction.
    if texts_df["trial_nr"][word_idx] > n_context_words+1:
      print(word_idx, texts_df["trial_nr"][word_idx], word)
      
      # get previous words:
      previous_context = ' '.join(texts_df["word_punct"][word_idx-1-n_context_words:word_idx-1])
      
      # compute surprisal score & entropy:
      curr_surprisal, curr_entropy = vanilla_next_word_surprisal_entropy(previous_words = previous_context, actual_word = word, model = model)

      # save them in df:
      texts_df['surprisal_2_words_context'][word_idx] = curr_surprisal
      texts_df['entropy_2_words_context'][word_idx] = curr_entropy

# reset warnings
warnings.resetwarnings()


# download the df:
texts_df.to_csv("/Users/merle/GitHub/PhD/EXNAT/Surprisal_Score_Tests/vanilla_2words_surprisal_entropy.csv", encoding = "utf-8-sig")



