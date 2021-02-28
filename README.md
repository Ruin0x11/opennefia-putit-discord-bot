# OpenNefia Discord Bot

Small test for a potential Discord bot. It's written in Lua and loads the entire game engine so you can call out to it remotely.

## Installation

```
lit install SinisterRectus/discordia
luvit main.lua
```

## Usage

- `!help` - Lists commands.
- `!exec` - Runs Lua code on OpenNefia's runtime. Pretty dangerous as nothing in the engine is thread-safe. Only useable by `Admin`s.
- `!reset` - Resets the global state of the engine (current map, player, config, save). Only useable by `Admin`s.
