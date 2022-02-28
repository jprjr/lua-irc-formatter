# lua-irc-formatter

A simple formatter/serializer for IRC messages.

It allows creating a formatter object with default values
for your messages. You can then serialize/format your messages
and have your defaults merged in.

For example, say you were building a bot that intends to
message the same room, you can create a formatter with
a pre-filled `command` and `params` value:

```lua
local formatter = require('irc-formatter').new({
  command = 'PRIVMSG',
  params = { '#some-room' },
})
```

Then to send messages, you call `:format` with
your additional parameter (the room message):

```lua
local str = formatter:format({
  params = { 'Hello there!' },
})

--[[ str is:
PRIVMSG #some-room :Hello there!
]]
```

If you provide some kind of invalid data, by default `:format()` will
throw an error. You can check for this beforehand using `:validate()`:

```lua
local formatter = require('irc-formatter').new({
  command = 'PRIVMSG',
  params = { '#some-room', 'param with spaces', 'another param with spaces' },
})

local ok, err = formatter:validate()
```

You can also `:validate()` with a table, and the merged parameters
will be tested:

```lua
local formatter = require('irc-formatter').new({
  command = 'PRIVMSG',
  params = { '#some-room'},
})

local ok, err = formatter:validate({
  params = { 'this has spaces', 'and so does this' },
})
```

This will properly escape tags, too. There's also a dedicated
type for generating "missing" tags (where there's no equals sign or value,
just the tag name):

```lua
local formatter = require('irc-formatter').new()

local str = formatter:format({
    tags = {
      a = ':-) Hi there;\r\n\\s',
      b = false,
      c = formatter.missing,
      d = 1234,
    },
    source = {
      nick = 'nick',
      user = 'user',
      host = '127.0.0.1',
    },
    command = 'PRIVMSG',
    params = { '#some-room', ':-)Hello there!' },
})
```

This will encode to:

```
@a=:-)\sHi\sthere\:\r\n\\s;b=false;c;d=1234 :nick!user@127.0.0.1 PRIVMSG #some-room ::-)Hello there!
```

By default, the strings are returned without a line-ending, this can
be set with the `eol` parameter.

The full list of parameters is:

* `tags` - a table of tags, values will be converted to strings using `tostring`.
* `source` - a table indicating the message source, formerly called `prefix`,
 it can have the following keys:
   * `nick`
   * `user`
   * `host`
* `command` - the only required parameter, the IRC Command.
* `params` - an array-like table of parameters
* `eol` - an end-of-line marker, like `\r\n`.

## Installation

### luarocks

Available on [luarocks](https://luarocks.org/modules/jprjr/irc-formatter):

```bash
luarocks install irc-formatter
```

### OPM

Available on [OPM](https://opm.openresty.org/package/jprjr/irc-formatter/)

```bash
opm install jprjr/irc-formatter
```

## LICENSE

MIT (see file `LICENSE`)
