local function sigmoid_derivative(dot_product, is_positive)
  -- adjust gradient towards neg or pos
  local sig = 1 / (1 + math.exp(-dot_product))
  local gradient = sig * (1 - sig)
  return is_positive and -gradient or gradient
end


local function propagate(embeddings, learn_rate, is_positive)
  -- propagate adjustments through message embeddings
  local sum = 0
  for i = 1, #embeddings do
    if embeddings[i] then
      local embed_val = embeddings[i][2]

      for k = 1, #embed_val do
        local bias = sum + embed_val[k]
        local gradient = sigmoid_derivative(embed_val[k] * bias, is_positive)
        embed_val[k] = embed_val[k] - learn_rate * gradient * bias
        sum = bias + learn_rate * gradient * embed_val[k]
      end

    else
      embeddings[i] = nil
    end
  end
  return embeddings
end


local function update_embedings(tensor_matrix, staging_words, embeddings, learn_rate, is_positive)
  propagate(embeddings, learn_rate, is_positive)

  for n = 1, #embeddings do -- update embedded vectors
    if embeddings[n] then
      local word = embeddings[n][1]
      local vector = embeddings[n][2]

      if tensor_matrix[word] then -- embeddings on file
        for k = 1, #vector do
          tensor_matrix[word][k] = vector[k]
        end

      elseif staging_words[word] then  -- words not yet seen N amount
        for k = 1, #vector do
          staging_words[word].vector[k] = vector[k]
        end
      end
    end
  end
  return tensor_matrix
end

return update_embedings
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