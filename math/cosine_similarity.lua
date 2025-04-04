-- for finding similar words based on the vector direction
local function cosine_similarity(vec1, vec2)
  local sum, norm1, norm2 = 0, 0, 0

  for i = 1, #vec1 do
    sum = sum + vec1[i] * vec2[i]
    norm1 = norm1 + (vec1[i] * vec1[i])
    norm2 = norm2 + (vec2[i] * vec2[i])
  end

  if norm1 == 0 or norm2 == 0 then
    return 0
  end

  return sum / (math.sqrt(norm1) * math.sqrt(norm2))
end

-- BUG: If a word has no similar words (as is the case when a new word is added to staging)
local function get_cosine_similarities(target_word, tensor_matrix, staging_words)
  local target_embedding = tensor_matrix[target_word] or staging_words[target_word]

  local similarities = {}
  -- first check the permanent tensors
  for word, vector in pairs(tensor_matrix) do
    if word and word ~= target_word then
      table.insert(similarities, {
        word = word,
        similarity = cosine_similarity(target_embedding, vector),
        vector = vector
        }
      )
    end
  end

  -- if the word didn't exist in permanent, it exists in staging
  for word, data in pairs(staging_words) do
    if word and word ~= target_word then
      table.insert(similarities, {
        word = word,
        similarity = cosine_similarity(target_embedding, data.vector),
        vector = vector
        }
      )
    end
  end

  table.sort(similarities,
    function(a, b)
      return a.similarity > b.similarity 
    end
  )

  similarities[0] = {}

  if not next(similarities[1]) then
    return similarities
  end

  for n = #similarities, 1, -1 do -- trim away everything except top N similar words
    if n <= 10 and n > 0 then
      local vector = similarities[n].vector

      for v = 1, #vector do  -- index 0 reserved contains only values for MAD use
        table.insert(similarities[0], vector[v])
      end

    else -- drop everything else we dont use
      similarities[n] = nil
    end
  end
  return similarities
end

return get_cosine_similarities



------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2025 monk                                                          --
--                                                                                --
-- Permission is hereby granted, free of charge, to any person obtaining a copy   --
-- of this software and associated documentation files (the "Software"), to deal  --
-- in the Software without restriction, including without limitation the rights   --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      --
-- copies of the Software, and to permit persons to whom the Software is          --
-- furnished to do so, subject to the following conditions:                       --
--                                                                                --
-- The above copyright notice and this permission notice shall be included in all --
-- copies or substantial portions of the Software.                                --
--                                                                                --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  --
-- SOFTWARE.                                                                      --
------------------------------------------------------------------------------------