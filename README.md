# Template Lua (LÖVE2D)

A project template for [LÖVE2D](https://love2d.org/) games, with linting, testing, CI, and a standard open-source project structure.

## Prerequisites

- [LÖVE2D](https://love2d.org/) 11.x+
- [LuaRocks](https://luarocks.org/)
- [Luacheck](https://github.com/mpeterv/luacheck)
- [Busted](https://olivinelabs.com/busted/)

## Quick Start

```bash
make setup   # Install dependencies
make run     # Run the game
make test    # Run tests
make check   # Lint code
make build   # Package into .love file
make help    # Show all targets
```

## Project Structure

```
src/           # Game source code
  main.lua     # Entry point (love.load/update/draw)
  conf.lua     # LÖVE2D configuration
tests/         # Busted test specs
assets/        # Game assets (images, sounds, etc.)
build/         # Build output (generated)
```

## License

[MIT](LICENSE)
