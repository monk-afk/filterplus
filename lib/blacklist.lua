--[[
  have a more robust list doesn't affect the results of the cosine similarity search.
  for example, after 10 epochs, the top ten will return with words not listed in the blacklist:

$ lua init.lua search=fuck
Similar Word	Similarity
     fucking 	 0.99988
        shit 	 0.99807
       bitch 	 0.99514
         sex 	 0.99426
       pussy 	 0.99288
      fucked 	 0.99282
      fuckin 	 0.99244
        sexy 	 0.99235
        cock 	 0.99079
       fuckk 	 0.99065

]]

return {
  "fuck",
  "cunt",
  "bitch",
  "cock",
  "nigger",
  "pussy",
  "piss",
  "shit",
  "bastard",
  "chinga",
  "sex",
  "asshole",
  "dick",
}