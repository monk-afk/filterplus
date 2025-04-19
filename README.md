# FilterPlus+ (pre-Alpha)

Concept: a chat filter using word embeddings and Lua pattern matching

## Abstract

What this project hopes to accomplish is to leverage the same methods used to train neural networks, with a focus on curses in a chat stream. The goal is to avoid using a whitelist, and possibly blacklist-pattern matching.

It this current state, filtering *mostly* works.

This is only the concept "alpha" release, which is also being released with known issues.

## Potential issues

1. The filter is a self-supervised process without a validation method.

2. Gradient drift. After several epochs of training, it was observed that embeddings will decay and drift from one cosine cluster to another.

3. There's no way to manually trigger a positive/negative embedding adjustment. 

4. Will miss mutations like: `a$$` or `$#!t`, or `sh it`.

5. First message sets the MAD-EMA threshold, if the message is very high or low MAD the EMA may take several messages before reflecting the true average.

6. Initial embeddings receive a default tensor of 0.3, and its gradient will reflect that of its neighbours.

## Process flow

A few definition generalizations before running through the process:

  - `Mean Absolute Deviation (MAD)`: used to evaluate whether a word "sticks out" in a message, as calculated from the word embeddings.
  - `Cosine Similar`: refers to either an individual word or a list of words which have similar embedding directions.
  - `Exponential Moving Average (EMA)`: A rolling average of a given value.

Here's how it works, after receiving a message:

1. Sanitize.

2. Set or update the `MAD-EMA` threshold.

3. Compare the `MAD` value against the `MAD-EMA` threshold.
    - If it is lower than the threshold, the message is not processed further and sent to chat.

4. Individually calculate the cosine similarity words' vectors into an average.

5. If the cosine similar words bias trends above the initial value of a tensor (0.3), that word in the message is censored.

6. If the `MAD-EMA` threshold was exceeded, regardless of being censored, update the embeddings using sigmoid.

7. Every 14500 messages, clear the staging table of infrequently used words.

## Set Up

  1. Create a list of common words to be ignored (`run/extract_common.lua`). Make sure to review the list and remove any curses.

  2. Add words to filter lists, whitelist, blacklist, curselist.
    - Whitelist words will not cause the tokenizer to flag message
    - Blacklist words will raise a flag from words matched by a loose-pattern; eg, fuck
    - Curselist is for confirmation, and should be an exhaustive list of mutations, misspellings, and mutations (no spaces). eg, fucking, fok, fack, etc.
    - > I realize this is over-the-top complicated, and welcome suggestions to effectively filter a large dataset with minimal false-positives.

  2. Get a bunch of data of chat messages or text containing curse words and non-curse words:

  https://huggingface.co/datasets/declip/Minecraft-Server-Chat

  https://huggingface.co/datasets/darkcleopas/jigsaw-toxic-comment-multi-binary

  3. Tokenize the dataset by running `$ lua init.lua tokenize`. This will read and tokenize lines using the blacklist pattern-matching filter. The end result is a file containing the sanitized lines prefixed with true or false:

    - `true:this message is fucked`
    - `false:this message is not`

  4. Train the embeddings by running `$ lua init.lua train`. By default, training will run for 5 epochs, with a learn rate of 0.00001, and save a 20 dimention vector for each embedding in `lib/embeddings.lua`.

  5. Run the filter process with `$ lua init.lua main`, currently accepts piped input from stdin which could be changed to read lines from file instead (line 59: `while true do  -- this is the main loop`)

___

### Other stuff

+ `$ lua init.lua search=fuck`
  - This will return with a list of similarly embedded words and their bias trend.

+ `run/signal.lua` contains a return statement. A running process can be terminated gracefully (triggering a save) by changing the return statement to false.

___

### What's next?

- Test with larger data set.
- Figure out a better way to tokenize
- Organize the files