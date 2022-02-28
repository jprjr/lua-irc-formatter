package = "irc-formatter"
version = "@VERSION@-1"

source = {
  url = "https://github.com/jprjr/lua-irc-formatter/releases/download/v@VERSION@/irc-formatter-@VERSION@.tar.gz"
}

description = {
  summary = "A library for parsing IRC lines",
  homepage = "https://github.com/jprjr/lua-irc-formatter",
  license = "MIT"
}

build = {
  type = "builtin",
  modules = {
    ["irc-formatter"] = "src/irc-formatter.lua",
  }
}

dependencies = {
  "lua >= 5.1",
}

