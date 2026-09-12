const Spell = require('views/play/level/tome/Spell')

describe('Spell.translateCommentContext', function () {
  const source = '# <%= greet %>\n# <%= parens %>\nhero.moveXY(1, 2)\n'
  const commentContext = { greet: 'Say hi', parens: 'Use parentheses' }
  const translate = (args) => Spell.prototype.translateCommentContext(args)

  let previousLanguage
  beforeEach(function () {
    previousLanguage = me.get('preferredLanguage')
    me.set('preferredLanguage', 'nl')
  })
  afterEach(function () { me.set('preferredLanguage', previousLanguage) })

  it('falls back to English per key when the locale context is incomplete', function () {
    const commentI18N = { nl: { context: { greet: 'Zeg hoi' } } }
    const result = translate({ source, commentContext, commentI18N, codeLanguage: 'python', spokenLanguage: 'nl' })
    expect(result).toBe('# Zeg hoi\n# Use parentheses\nhero.moveXY(1, 2)\n')
    expect(result).not.toMatch(/<%=/)
  })

  it('uses the complete locale context as before', function () {
    const commentI18N = { nl: { context: { greet: 'Zeg hoi', parens: 'Gebruik haakjes' } } }
    const result = translate({ source, commentContext, commentI18N, codeLanguage: 'python', spokenLanguage: 'nl' })
    expect(result).toBe('# Zeg hoi\n# Gebruik haakjes\nhero.moveXY(1, 2)\n')
  })

  it('keeps the Lua method-call rewrite on English fallback keys', function () {
    const luaSource = '-- <%= greet %>\n-- <%= parens %>\n'
    const luaContext = { greet: 'Call hero.say()', parens: 'Use parentheses' }
    const commentI18N = { nl: { context: { parens: 'Gebruik haakjes' } } }
    const result = translate({ source: luaSource, commentContext: luaContext, commentI18N, codeLanguage: 'lua', spokenLanguage: 'nl' })
    expect(result).toBe('-- Call hero:say()\n-- Gebruik haakjes\n')
  })

  it('renders English when there is no i18n', function () {
    const result = translate({ source, commentContext, commentI18N: undefined, codeLanguage: 'python', spokenLanguage: 'nl' })
    expect(result).toBe('# Say hi\n# Use parentheses\nhero.moveXY(1, 2)\n')
  })
})
