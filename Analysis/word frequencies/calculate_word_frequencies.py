
"""
Calculate word frequencies for EXNAT Pilot1

Input: 1 csv file containing 3 columns: 
    - word (with single words w/o punctuation)
    - text_nr (1_01 - 1_09 and 2_01 - 2_16)‚
    - word_frequency (all set as 0)

Output: The same csv, but with a word frequency 
       (in the column word_frequency) for each word.
       
 October 17th 2022, written by Merle Schuckart      

"""


""" Import packages"""
# for setting working directory
import os 
from pathlib import Path
# for getting word frequencies:
from wordfreq import word_frequency 
# You have to pip install this before importing it
# wordfreq citation: 
# Speer, R., Chin, J., Lin, A., Jewett, S., & Nathan, L. (2018, October 3). LuminosoInsight/wordfreq: v2.2. Zenodo. https://doi.org/10.5281/zenodo.1443582

import pandas as pd # for doing stuff with data frames


""" Read in dataset """

# Navigate to the directory containing your script
file_path = Path(os.getcwd()).parent.joinpath("EXNAT-1/Analysis/Word_frequencies")

# Change to the desired directory
os.chdir(file_path)

# read in dataset from wd
word_freq_data = pd.read_csv("Word_freqs.csv", sep = ";")

""" Loop words, get frequency for each """ 
for row_idx in range(0, len(word_freq_data)):
    # get current word
    curr_word = word_freq_data['word'][row_idx]
    # get word frequency for current word and put it into df
    word_freq_data['word_frequency'][row_idx] = word_frequency(curr_word, 
                                                               "de", 
                                                               wordlist = 'best', 
                                                               minimum = 0.0)

""" overwrite old csv with edited df """
# Done, export as csv (replace the old one in the folder
word_freq_data.to_csv(path_or_buf="Word_freqs.csv", 
                 sep=';', na_rep='', header=True, storage_options=None)

