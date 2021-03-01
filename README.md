# OpenNefia Discord Bot

Small test for a potential Discord bot. It's written in Lua and loads the entire game engine so you can call out to it remotely.

## Installation

1. Put the bot's token into a `secret.lua` file that looks like this.

``` lua
return {
   token = "<bot client key>"
}
```

2. Install luvit and discordia.

```
lit install SinisterRectus/discordia
```

3. Run the bot.

```
luvit main.lua
```

You might have to manually unpack an Elona 1.22 install from `deps/elona` into `graphic/` and `mod/elona/sound/`, but after that it should be fine.

## Usage

- `!help` - Lists commands.
- `!exec` - Runs Lua code on OpenNefia's runtime. Pretty dangerous as nothing in the engine is thread-safe. Only useable by `Admin`s.
- `!reset` - Resets the global state of the engine (current map, player, config, save). Only useable by `Admin`s.
