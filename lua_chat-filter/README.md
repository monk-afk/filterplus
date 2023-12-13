## Chat Filter -- Lua Portable

Chat Message Filter and Censor Module, with Index-Key Associated Blacklist.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023-2024, Licensed under CC0</sup>

##
This portable module provides a functional starting point for a chat/message filter.

Messages are filtered using blacklist words by associating suffix->prefix->word.  It removes extra whitespace, non-alphabet characters, duplicated letters, ~~and joins gapped words~~(nf) before the index search.

Table structre:
```lua
k = { m = { "monk" },
      l = { "link" } },
e = { f = { "face", "frostbite" } }
```

For importing, replace the 'fakechat' lines with compatible code.

##
### Version **`dev_0.05`**