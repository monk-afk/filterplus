local function get_tensor(clip)
  local graduation_threshold = 3  -- number of times a word must be seen before being added to the tensor matrix
  local vector_layers = clip.param_vector_layers
  local tensor_matrix = {}
  local staging_words = {}

  local check_file = io.open(clip.lib_embeddings)

  if check_file then
    check_file:close()
    tensor_matrix = dofile(clip.lib_embeddings)
  end

  check_file = nil

  return function(word, tensor_matrix, staging_words)
    if word and #word >= 1 and #word <= 18 then  -- limit length
      if not tensor_matrix[word] then -- if word doesn't exist in tensor_matrix
        if not staging_words[word] then -- new word has not been encountered
          staging_words[word] = {
            count = 0, vector = {}
          }

          for d = 1, vector_layers do
            staging_words[word].vector[d] = 0.3
          end

          return staging_words[word].vector

        elseif staging_words[word].count >= graduation_threshold then -- already seen many times, move it to tensor_matrix
          tensor_matrix[word] = {}

          for d = 1, vector_layers do -- copy the tensor values
            tensor_matrix[word][d] = staging_words[word].vector[d]
          end

          staging_words[word] = nil

          return tensor_matrix[word]

        else -- word is still fresh, we'll use a temporary table to return with
          staging_words[word].count = staging_words[word].count + 1

          local temporary_matrix = {}

          for d = 1, vector_layers do
            temporary_matrix[d] = staging_words[word].vector[d]
          end

          return temporary_matrix
        end
      end

      return tensor_matrix[word]

    else -- word exceeds limits, return baseline tensor
      local temporary_matrix = {}

      for d = 1, vector_layers do
        temporary_matrix[d] = 0.3
      end

      return temporary_matrix
    end
  end, tensor_matrix, staging_words
end

return get_tensor



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