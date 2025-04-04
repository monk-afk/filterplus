# FilterPlus+ (pre-Alpha)

Concept: a chat filter using word embeddings and Lua pattern matching

## Abstract

What this project hopes to accomplish is to leverage the same methods used to train neural networks, with a focus on curses in a chat stream. The goal is to avoid using a whitelist, and possibly blacklist-pattern matching.

It this current state, filtering *mostly* works.

This is only the concept "alpha" release, which is also being released with known issues.

## Known issues

1. Censor evaluation needs improvement. Using RMS-MAD is not the best and should be replaced.

2. Blacklist-pattern matching. Nothing inherently wrong with this, but is a bottleneck. It would be worth experiment without the blacklist method.

3. There's no way to manually trigger a positive/negative embedding adjustment. 

4. Crash occurs during a very specific condition. If a word is new or relatively new (with embeddings close to the starting values), and also triggers a flag from the blacklist closure, the cosine similarity search will yield no similar words and causes a nil value on the similarities table. I added an untested next() check just as a quick fix.

5. After the inital tokenizing, the file `lib/eval_flags.txt` shows words which have been merged. This likely happens during the sanitizing.

6. Will miss mutations like: `a$$` or `$#!t`.

## Process flow

A few definition generalizations before running through the process:

  - `Mean Absolute Deviation (MAD)`: used to evaluate whether a word "sticks out" in a message, as calculated from the word embeddings.
  - `Cosine Similar`: refers to either an individual word or a list of words which have similar embedding directions.
  - `Exponential Moving Average (EMA)`: A rolling average of a given value.
  - `Root Mean Squared (RMS)`: The square root of an accumulated sum of square roots.

Here's how it works, after receiving a message:

1. The very first step is to update the `MAD-EMA` threshold. This will cause the very first message received to set the threshold's initial baseline.

2. Compare the `MAD` value against the `MAD-EMA` threshold.
  - If it is lower than the threshold, the message is not processed further and sent to chat.

2. Run the message through the blacklist pattern search.
  - The pattern should be loose enough to capture various mutations, ~~including numbers and symbols,~~ repeating characters and curses with prefixes and suffixes. False-positive blacklist-pattern matches are expected.

> As i'm writing this next step, I'm realizing there is a process flow issue which can be improved or changed entirely.

3. For each word returned from the blacklist-pattern match, gather the list of top-N `cosine similar` words, and accumulate those words' embeddings' MAD value.

> Step 4 will likely change. The previous step is accumulating MAD values of flagged words, and calculating the square root of the mean will not accurately measure the intention of using the MAD values of the cosine similar words.

4. The `RMS` of the accumulated scores of the words flagged by the blacklist-pattern search is evaluated.


> I'm just going to stop writing this here because the flow will change (again). 
> Perhaps the RMS can be scrapped, or could be better applied (eg; not with MAD)
> Using the MAD value of the cosine similar words is also incorrect, as it wouldn't capture the deviations of the flagged word, since their cosine similar words *are similar*.


## Set Up

  1. Populate the `blacklist.lua` with some words to be filtered.
    - > what about the whitelist?

  2. Get a data set of chat messages or text containing curse words and non-curse words:

  https://huggingface.co/datasets/declip/Minecraft-Server-Chat

  https://huggingface.co/datasets/darkcleopas/jigsaw-toxic-comment-multi-binary

  3. Pre-process the dataset by running `$ lua init.lua eval`. This will read the dataset and tokenize lines using the blacklist pattern-matching filter.

  4. Train the embeddings by running `$ lua init.lua train`. To automatically start training after tokenizing the dataset, multiple parameters are accepted from the command line: `$ lua init.lua eval train ep=10`. For a full list of parameters, run `$ lua init.lua help`

When training is complete, there will exist `lib/tokens.lua` and `lib/embeddings.lua`.

___

## Post-processing

**Cosine Similarity Search**

+ To test the embeddings in the tensor matrix, run `$ lua init.lua search=fuck`. This will search the embeddings and return with a list of similarly embedded words. 

+ If after training the words are not what you expect (for example, searching for `fuck` typically shouldn't return with a list of flowers and rainbows), it is recommended to retrain the embeddings for several more epochs. Run `$ lua init.lua train` and the trainer will resume training on the existing `embeddings.lua` file.

+ To terminate gracefully at any point in the process, from evaluation through training, by writing to `run/signal.lua` with: `return false`. This will allow the embeddings to be saved to file, and the program to quit.

+ Updates to tokens in `tokens.lua` won't disrupt the training process as long as there is sufficient time to train the embeddings.

+ Deleting the `tokens.lua` file will force the process to generate new tokens from the dataset in the corpus directory.

+ To apply the filter to a chat stream, run with `$ lua init.lua main`. This will start a session and receive input from stdin.

**Previous notes**

Pre-processing:
  Messages are sanitized (lowercased, stripped of accents, symbols mapped to letters).

Mean Absolute Deviation (MAD) Screening:
  Computes the Root Mean Squared (MAD) value of word embeddings.

  If MAD < threshold, the message is considered safe and skipped.

  If MAD ≥ threshold, proceed to blacklist checks.

Blacklist Matching:

  If a blacklisted pattern is detected, words flagged by the pattern become the blacklisted context.

  The MAD value of the blacklisted context is compared against the threshold.

Cosine-MAD:

  If the blacklisted context MAD is above the threshold, the MAD value of cosine similar words are measured against the threshold.

  If the cosine-MAD determines is above the threshold, the word is determined to be vulgar and therefore censored.

Tensor Updates:

  Sigmoid-based learning is applied to adjust embeddings dynamically.

Recent Improvements:

Optimized MAD Filtering to reduce unnecessary blacklist checks.

Sigmoid Function for Word Embeddings to ensure non-linear updates.

Integrated Learning Mechanism using a propagation function that updates word embeddings in real time.

Implemented Exponential Moving Average (EMA) to adjust the MAD threshold dynamically based on chat activity.

Reduce Low-frequency words clutter the dataset using a staging system:
  - New words start in staging_words with a default vector.
  - After appearing 5+ times, they move to the tensor_matrix.
  - Words in tensor_matrix that become inactive over time should be dropped, but I’m unsure how to do this efficiently without parsing the entire table.
