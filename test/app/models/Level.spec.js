/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const SuperModel = require('models/SuperModel')
const Level = require('models/Level')
const ThangType = require('models/ThangType')

describe('Level', () => describe('denormalize', function () {
  const level = new Level({
    thangs: [
      {
        thangType: 'A',
        id: 'Tharin',
        components: [
          { original: 'a', majorVersion: 0 },
          { original: 'b', majorVersion: 0, config: { i: 2 } },
          { original: 'c', majorVersion: 0, config: { i: 1, ii: 2, nest: { iii: 3 } } },
          // should add one more
        ],
      },
    ],
    type: 'hero',
  })

  const thangType = new ThangType({
    original: 'A',
    version: { major: 0, minor: 0 },
    components: [
      { original: 'a', majorVersion: 0, config: { i: 1 } },
      { original: 'c', majorVersion: 0, config: { i: 3, nest: { iv: 4 } } },
      { original: 'd', majorVersion: 0, config: { i: 1 } },
    ],
  })

  const supermodel = new SuperModel()
  supermodel.registerModel(thangType)

  const result = level.denormalize(supermodel)
  const tharinThangComponents = result.thangs[0].components

  it('adds default configs to thangs without any config', function () {
    const aComp = _.find(tharinThangComponents, { original: 'a' })
    return expect(_.isEqual(aComp.config, { i: 1 })).toBeTruthy()
  })

  it('leaves alone configs for components the level thang has but the thang type does not', function () {
    const bComp = _.find(tharinThangComponents, { original: 'b' })
    return expect(_.isEqual(bComp.config, { i: 2 })).toBeTruthy()
  })

  it('merges configs where both the level thang and thang type have one, giving priority to the level thang', function () {
    const cComp = _.find(tharinThangComponents, { original: 'c' })
    return expect(_.isEqual(cComp.config, { i: 1, ii: 2, nest: { iii: 3, iv: 4 } })).toBeTruthy()
  })

  return it('adds components from the thang type that do not exist in the level thang', function () {
    const dComp = _.find(tharinThangComponents, { original: 'd' })
    expect(dComp).toBeTruthy()
    return expect(_.isEqual(dComp != null ? dComp.config : undefined, { i: 1 })).toBeTruthy()
  })
}))

describe('Level starter-code comment context', function () {
  const makeLevel = (i18n) => new Level({
    type: 'hero',
    thangs: [
      {
        id: 'Hero Placeholder',
        components: [
          {
            original: 'programmable',
            majorVersion: 0,
            config: {
              programmableMethods: {
                plan: {
                  source: '// <%= greet %>\n// <%= parens %>\n',
                  languages: { python: '# <%= greet %>\n# <%= parens %>\n' },
                  context: { greet: 'Say hi', parens: 'Use parentheses' },
                  solutions: [{ language: 'python', succeeds: true, source: '# <%= greet %>\n# <%= parens %>\nhero.say("hi")' }],
                  i18n,
                },
              },
            },
          },
        ],
      },
    ],
  })

  let previousLanguage
  beforeEach(function () {
    previousLanguage = me.get('preferredLanguage')
    me.set('preferredLanguage', 'nl')
  })
  afterEach(function () {
    me.set('preferredLanguage', previousLanguage)
  })

  it('falls back to the English comment for keys the locale context is missing', function () {
    const level = makeLevel({ nl: { context: { greet: 'Zeg hoi' } } })
    const code = level.getSampleCodeForLanguage('python')
    expect(code).toBe('# Zeg hoi\n# Use parentheses\n')
    expect(code).not.toMatch(/<%=/)
  })

  it('falls back to English for blank locale translations', function () {
    const level = makeLevel({ nl: { context: { greet: '   ', parens: 'Gebruik haakjes' } } })
    expect(level.getSampleCodeForLanguage('python')).toBe('# Say hi\n# Gebruik haakjes\n')
  })

  it('uses the locale context fully when it is complete, stripping AI markers', function () {
    const level = makeLevel({ nl: { context: { greet: '[AI_TRANSLATION]Zeg hoi', parens: 'Gebruik haakjes' } } })
    expect(level.getSampleCodeForLanguage('python')).toBe('# Zeg hoi\n# Gebruik haakjes\n')
  })

  it('renders English when the locale has no context at all', function () {
    const level = makeLevel({ nl: { name: 'Naam' } })
    expect(level.getSampleCodeForLanguage('python')).toBe('# Say hi\n# Use parentheses\n')
  })

  it('leaves English rendering unchanged', function () {
    me.set('preferredLanguage', 'en-US')
    const level = makeLevel({ nl: { context: { greet: 'Zeg hoi' } } })
    expect(level.getSampleCodeForLanguage('javascript')).toBe('// Say hi\n// Use parentheses\n')
  })

  it('applies the same merge to solutions', function () {
    const level = makeLevel({ nl: { context: { greet: 'Zeg hoi' } } })
    const solution = level.getSolutionForLanguage('python')
    expect(solution.source).toBe('# Zeg hoi\n# Use parentheses\nhero.say("hi")')
  })
})
