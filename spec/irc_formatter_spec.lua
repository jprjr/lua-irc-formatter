local formatter = require'irc-formatter'

describe('irc-formatter', function()
  it('should allow creating a formatter with empty defaults', function()
    assert.is_table(formatter.new())
    assert.is_table(formatter.new({}))
  end)

  it('should allow creating a formatter with invalid defaults', function()
    assert.is_table(formatter.new({
      command = '001',
      params = { 'this is', 'invalid' },
    }))
  end)

  it('should have a custom type representing missing values', function()
    local t = formatter.new({})
    assert.is_table(formatter.missing)
    assert.is_table(t.missing)
    assert.is_same(t.missing,formatter.missing)
  end)

  it('should validate without throwing errors', function()
    local f = formatter.new({})
    local ok, err = f:validate()
    assert.is_nil(ok)
    assert.is_string(err)
  end)

  it('should error when serializing with no command', function()
    local f = formatter.new({})
    assert.has_error(function() f:serialize() end)
  end)

  it('should not error with __tostring', function()
    local f = formatter.new({})
    assert.not_has_error(function() tostring(f) end)
  end)

  it('should error when serializing with invalid params', function()
    local f = formatter.new({
      command = '001',
      params = { 'this is', 'invalid' },
    })
    assert.has_error(function() f:serialize() end)
  end)

  it('should support a host alone', function()
    local f = formatter.new({
      source = {
        host = '127.0.0.1',
      },
      command = '001',
    })
    assert.is_equal(':127.0.0.1 001',f:serialize())
  end)

  it('should support a nick alone', function()
    local f = formatter.new({
      source = {
        nick = 'nick',
      },
      command = '001',
    })
    assert.is_equal(':nick 001',f:serialize())
  end)

  it('should support a nick with user', function()
    local f = formatter.new({
      source = {
        nick = 'nick',
        user = 'user',
      },
      command = '001',
    })
    assert.is_equal(':nick!user 001',f:serialize())
  end)

  it('should support a nick with host', function()
    local f = formatter.new({
      source = {
        nick = 'nick',
        host = '127.0.0.1',
      },
      command = '001',
    })
    assert.is_equal(':nick@127.0.0.1 001',f:serialize())
  end)

  it('should support a nick with user and host', function()
    local f = formatter.new({
      source = {
        nick = 'nick',
        user = 'user',
        host = '127.0.0.1',
      },
      command = '001',
    })
    assert.is_equal(':nick!user@127.0.0.1 001',f:serialize())
  end)

  it('should error with a user and no nick', function()
    local f = formatter.new({
      source = {
        user = 'user',
      },
      command = '001',
    })
    assert.has_error(function() f:serialize() end)
  end)

  it('should serialize messages', function()
    local result = '@a=:-)\\sHi\\sthere\\:\\r\\n\\\\s;b=false;c;d=1234 :nick!user@127.0.0.1 PRIVMSG #some-room ::-)Hello there!'
    assert.is_equal(
      formatter.new({
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
      }):serialize(),result)
  end)

  it('should allow setting and merging defaults', function()
    local result = '@a=:-)\\sHi\\sthere\\:\\r\\n\\\\s;b=false;c;d=1234 :nick!user@127.0.0.1 PRIVMSG #some-room ::-)Hello there!\r\n'
    local f = formatter.new({
        tags = {
          a = ':-) Hi there;\r\n\\s',
        },
        source = {
          host = '127.0.0.1',
        },
        command = 'PRIVMSG',
        params = { '#some-room' },
        eol = '\r\n',
      })
    assert.is_equal(f:serialize({
      tags = {
        b = false,
        c = formatter.missing,
        d = 1234,
      },
      source = {
        nick = 'nick',
        user = 'user',
        host = '127.0.0.1',
      },
      params = {
        ':-)Hello there!',
      },
    }),result)
  end)

  it('should handle empty strings in params', function()
    local f = formatter.new({
      command = '001',
      params = { '' },
    })
    assert.is_equal('001 :',f:serialize())
  end)

  it('should convert non-strings commands to strings', function()
    local f = formatter.new({
      command = 300,
    })
    assert.is_equal('300',f:serialize())
  end)

  it('should convert commands < 100 to 3-digit strings', function()
    local f = formatter.new({
      command = 1,
    })
    assert.is_equal('001',f:serialize())
  end)

  it('should convert commands > 999 to 4-digit strings', function()
    local f = formatter.new({
      command = 1000,
    })
    assert.is_equal('1000',f:serialize())
  end)

  it('should reject non-integer, non-string commands', function()
    local f = formatter.new({
      command = true,
    })
    assert.has_error(function() f:serialize() end)
  end)

  it('should convert non-strings params to strings', function()
    local f = formatter.new({
      command = '001',
      params = { true },
    })
    assert.is_equal('001 true',f:serialize())
  end)

end)
