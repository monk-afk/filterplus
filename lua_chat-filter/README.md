## Chat Filter -- Lua Portable

Chat Message Filter and Censor Module, with Index-Key Associated Blacklist.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023-2024, Licensed under CC0</sup>

##
This portable module provides a functional starting point for a chat/message filter.

Messages are filtered using blacklist words by associating suffix->prefix->word.  

The filter removes URLs within strings, extra spaces, and joins gapped words.

Table structre:
```lua
k = { m = { "monk" },
      l = { "link" } },
e = { f = { "face", "frostbite" } }
```

For importing, replace the 'fakechat' lines with compatible code.

##

- init.lua `dev_0.07`
- blacklist.lua `0.02`