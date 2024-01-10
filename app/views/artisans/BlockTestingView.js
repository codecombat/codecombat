let BlockTestingView
require('app/styles/artisans/block-testing-view.sass')
const RootView = require('views/core/RootView')
const template = require('templates/artisans/block-testing-view')
const testTemplate = require('templates/artisans/block-testing-test')
const loadAetherLanguage = require('lib/loadAetherLanguage')
const blocklyUtils = require('core/blocklyUtils')
const Blockly = require('blockly')
const { codeToBlocks, prepareBlockIntelligence } = require('lib/code-to-blocks')
const aceLib = require('lib/aceContainer')
const aceUtils = require('core/aceUtils')
const storage = require('core/storage')
const utils = require('core/utils')
const Campaigns = require('collections/Campaigns')
const Level = require('models/Level')

const testCases = []
let levelTestsAdded = false
let propertyEntryGroups
let prepData = null

module.exports = (BlockTestingView = (function () {
  BlockTestingView = class BlockTestingView extends RootView {
    static initClass () {
      this.prototype.template = template
      this.prototype.id = 'block-testing-view'
      this.prototype.testCases = testCases
    }

    constructor (options, levelSlug) {
      super(options)
      blocklyUtils.registerBlocklyTheme()
      blocklyUtils.initializeBlocklyTooltips()
      this.focusTest = utils.getQueryVariable('test')
      this.focusLanguage = utils.getQueryVariable('codeLanguage')
      this.focusCampaign = utils.getQueryVariable('campaign')
      this.testSkip = parseInt(utils.getQueryVariable('skip', 0), 10)
      this.testLimit = parseInt(utils.getQueryVariable('limit', 100))
      this.blocklyWorkspaces = []

      if (!levelTestsAdded && (!this.focusTest || !(/^Level - /.test(this.focusTest)))) {
        this.campaigns = storage.load('blockly-test-campaigns')
        if (this.campaigns) {
          this.onLoaded()
        } else {
          this.campaignsCollection = new Campaigns()
          this.supermodel.trackRequest(this.campaignsCollection.fetch({ data: { project: 'slug,type,levels' } }))
          this.campaignsCollection.comparator = m => [
            'intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6',
            'dungeon', 'forest', 'desert', 'mountain', 'glacier', 'volcano',
            'campaign-game-dev-1', 'game-dev-1', 'campaign-game-dev-2', 'game-dev-2', 'campaign-game-dev-3', 'game-dev-3',
            'hoc-2018', 'game-dev-hoc', 'game-dev-hoc-2', 'ai-league-hoc'].indexOf(m.get('slug'))
        }
      } else {
        this.onLoaded()
      }
    }

    onLoaded () {
      super.onLoaded()
      if (this.campaignsCollection) {
        this.campaigns = this.campaignsCollection.models.map(m => m.attributes)
        storage.load('blockly-test-campaigns', this.campaigns, 24 * 60)
      }

      const levelSlugsSet = new Set()
      this.levelSlugs = []
      this.levels = []
      this.levelsToLoadRemaining = 0
      for (const campaign of this.campaigns || []) {
        if (levelTestsAdded) { break }
        if (['auditions', 'picoctf', 'web-dev-1', 'web-dev-2', 'js-primer', 'js-primer-playtest', 'web-dev-1', 'web-dev-2', 'campaign-web-dev-1', 'campaign-web-dev-2'].includes(campaign.slug)) { continue }
        if (this.focusCampaign && campaign.slug !== this.focusCampaign) { continue }
        for (const levelInfo of _.values(campaign.levels)) {
          const levelSlug = levelInfo.slug
          if (levelSlugsSet.has(levelSlug)) { continue }
          levelSlugsSet.add(levelSlug)
          this.levelSlugs.push(levelSlug)
          let level = storage.load(`blockly-test-level_${levelSlug}`)
          if (!level) {
            console.log(`Initial load to localStorage of level ${levelSlug}`)
            level = new Level({ _id: levelSlug })
            level.project = ['slug', 'thangs']
            ++this.levelsToLoadRemaining
            this.levels.push(level)
            this.listenToOnce(this.supermodel.loadModel(level).model, 'sync', this.onLevelLoaded)
          } else {
            this.levels.push(level)
          }
        }
      }
      if (this.levelsToLoadRemaining === 0) {
        this.onAllLevelsLoaded()
      }
    }

    levelToCode (level) {
      const result = {
        slug: level.get('slug'),
        sampleCode: level.getSampleCode(),
        solutionCodes: level.getSolutions()
      }
      return result
    }

    onLevelLoaded (level) {
      const result = this.levelToCode(level)
      storage.save(`blockly-test-level_${level.get('slug')}`, result)
      const idx = this.levels.indexOf(level)
      this.levels[idx] = result
      if (!--this.levelsToLoadRemaining) {
        this.onAllLevelsLoaded()
      }
    }

    onAllLevelsLoaded () {
      this.addLevelTestCases()
      // Ensure Esper is fully loaded, including babylon (used in Python)
      loadAetherLanguage('python').then((aetherLang) => {
        loadAetherLanguage('javascript').then((aetherLang) => {
          this.addTestCases()
        })
      })
    }

    addLevelTestCases () {
      if (levelTestsAdded) { return }
      for (const level of this.levels) {
        // if (this.focusTest && this.focusTest.indexOf(`Level ${level.slug} - `) === -1) { continue }
        for (const codeLanguage of ['python', 'javascript']) {
          const sampleCode = level.sampleCode[codeLanguage]
          if (sampleCode?.trim() && !/Should fill in some default source/.test(sampleCode)) {
            testCases.push({ name: `Level ${level.slug} - ${codeLanguage} - Starter`, codeLanguage, code: sampleCode })
          }
          const solutionCodeLanguageIndex = 0
          for (const solutionCode of level.solutionCodes) {
            if (solutionCode.codeLanguage !== codeLanguage) { continue }
            if (!solutionCode.source?.trim()) { continue }
            testCases.push({ name: `Level ${level.slug} - ${codeLanguage} - Solution ${++solutionCodeLanguageIndex}`, codeLanguage, code: solutionCode.source })
          }
        }
      }
      levelTestsAdded = true
    }

    addTestCases () {
      this.render()
      const testCasesContainer = this.$el.find('#test-cases-container')
      for (let i = this.testSkip; i < testCases.length && (this.focusTest || (i - this.testSkip < this.testLimit)); ++i) {
        const testCase = testCases[i]
        if (this.focusTest) {
          if (this.focusTest === testCase.name) {
            testCase.focused = true
          } else {
            continue
          }
        }
        if (this.focusLanguage && this.focusLanguage !== testCase.codeLanguage) {
          continue
        }

        const testCaseHtml = testTemplate({ testCaseIndex: i, testCase })
        let testContainer = $(testCaseHtml)
        testContainer.appendTo(testCasesContainer)
        testContainer = testCasesContainer.find('.test-case:last-child')
        testCase.code = testCase.code.trim()
        testCase.key = `${testCase.name}_${testCase.codeLanguage}_${hashString(testCase.code)}`
        const { inputAce, outputAce } = this.addAce({ testCase, testContainer })
        _.defer(() => this.addBlockly({ testCase, testContainer, inputAce, outputAce }))
      }
    }

    addAce ({ testCase, testContainer }) {
      const codeLanguage = testCase.codeLanguage
      const aces = { input: null, output: null }
      for (const key in aces) {
        const ace = aceLib.edit(testContainer.find(`.ace-${key}`)[0])
        this.configureAce(ace, testCase.codeLanguage)
        if (key === 'input') {
          ace.setValue(testCase.code)
          ace.clearSelection()
        } else {
          ace.setReadOnly(true)
        }
        aces[key] = ace
      }
      return { inputAce: aces.input, outputAce: aces.output }
    }

    addBlockly ({ testCase, testContainer, inputAce, outputAce }) {
      // Initialize Blockly
      const testBlockly = { loaded: false, loading: false, div: testContainer.find('.blockly-container')[0] }
      testBlockly.load = () => {
        const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: testCase.codeLanguage })
        const blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox })
        testBlockly.workspace = Blockly.inject(testBlockly.div, blocklyOptions)
        this.blocklyWorkspaces.push(testBlockly.workspace)
        testBlockly.loading = true
        testBlockly.workspace.addChangeListener((event) => {
          if (event.type === Blockly.Events.FINISHED_LOADING) {
            testBlockly.loading = false
            testBlockly.loaded = true
          } else if (testBlockly.loading) {
            return
          } else if (!blocklyUtils.blocklyMutationEvents.includes(event.type)) {
            return
          }
          // Blockly -> output ace
          // TODO: make sure it's the kind of change we want to do, we don't fire multiple changes for same source?
          const { blocklyState, blocklySource } = blocklyUtils.getBlocklySource(testBlockly.workspace, testCase.codeLanguage)
          console.log('New blockly state for', testCase.name, 'is', blocklyState)
          outputAce.setValue(blocklySource)
          outputAce.clearSelection()
          const inputSource = inputAce.getValue()
          if (inputSource === testCase.code) {
            let status = 'success'
            let reason = 'matched'
            const normalizeCode = (s) => {
              return s
                .replace(/"/g, '\'') // Treat single and double quotes the same
                .replace(/\\'/g, '\'') // Ignore escapes of single quotes, from above step
                .replace(/^(let|const) /gm, 'var ') // Treat var, let, and const the same
                .replace(/(\n *\n *)(\n *)+/g, '$1') // Ignore more than 2 newlines in a row
                .replace(/!==/g, '!=') // Ignore !== vs. !=
                .replace(/===/g, '==') // Ignore !== vs. !=
                .replace(/ +(\/\/|#|--) .*?[Δ∆].*$/gm, '') // Ignore in-line comments with deltas
                .replace(/;\n/g, '\n') // Ignore trailing semicolons
                .replace(/;\n +(\/\/|#|--).*?$/gm, '\n') // Ignore trailing semicolons before comments
                .replace(/;$/g, '') // Ignore trailing semicolons at end of program
                .replace(/(while|if|for|function) \(/g, '$1\(') // Ignore space between keyword and opening parenthesis
                .replace(/( *(\/\/|#|--).*?) +$/gm, '$1') // Ignore trailing spaces after code comments
                .trim()
            }
            // console.log('--------------------\n', normalizeCode(blocklySource), '\n================\n', normalizeCode(testCase.code), '\n++++++++++++++++++++++++')
            if (normalizeCode(blocklySource) !== normalizeCode(testCase.code)) {
              status = 'failure'
              reason = 'code-mismatch'
            } else if (blocklyUtils.blocklyStateIncludesBlockType(blocklyState, 'raw_code') || blocklyUtils.blocklyStateIncludesBlockType(blocklyState, 'raw_code_value')) {
              status = 'failure'
              reason = 'raw-code'
            }
            const result = { state: blocklyState, inputState: testCase.inputBlocklyState, outputCode: blocklySource, status, reason }
            storage.save(`blockly-test-from-code_${testCase.key}_${hashString(testCase.code)}`, result)
            testCase.status = status
            testCase.reason = reason
            testContainer.addClass(testCase.status)
            testContainer.find('.test-status').text(`${testCase.status} - ${testCase.reason}`) // TODO: dedupe
          }
        })
      }

      const errorDiv = testContainer.find('.error-scratchpad')[0]

      // If this is the first time, get some prep data for initial codeToBlocks setup.
      let prepDataError
      if (!prepData) {
        // debugBlocklyWorkspace is currently needed so we can go from block JSON -> block -> block output code using workspaceToCode
        // TODO: try to just do valueToCode or something so we don't even need a workspace
        // codeToBlocks prepareBlockIntelligence function needs the JavaScript version of the toolbox
        const toolboxJS = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: 'javascript' })
        const debugBlocklyDiv = testContainer.find('.blockly-container-debug')[0]
        const debugBlocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox: toolboxJS })
        const debugBlocklyWorkspace = Blockly.inject(debugBlocklyDiv, debugBlocklyOptions)
        this.blocklyWorkspaces.push(debugBlocklyWorkspace)
        try {
          prepData = prepareBlockIntelligence({ toolbox: toolboxJS, workspace: debugBlocklyWorkspace })
        } catch (err) {
          console.error(err)
          prepData = {}
          testContainer.find('debug-error').text(err.message).removeClass('hide')
          prepDataError = err
        }
      }

      const onAceChange = () => {
        const code = inputAce.getValue()
        const newBlocklyState = this.runCodeToBlocks({ testCase, code, codeLanguage: testCase.codeLanguage, errorDiv, prepData, prepDataError })
        if (!newBlocklyState) { return }
        const cachedBlocklyTest = storage.load(`blockly-test-from-code_${testCase.key}_${hashString(code)}`)
        if (!testBlockly.loaded &&
            !testCase.focused &&
            cachedBlocklyTest?.state &&
            (blocklyUtils.isEqualBlocklyState(newBlocklyState, cachedBlocklyTest?.state) ||
             blocklyUtils.isEqualBlocklyState(newBlocklyState, cachedBlocklyTest?.inputState))) {
          console.log('Skipping Blockly instantiation for cached Blockly test', testCase.name, 'with status', cachedBlocklyTest.status, 'and reason', cachedBlocklyTest.reason)
          testCase.status = cachedBlocklyTest.status
          testCase.reason = cachedBlocklyTest.reason
          if (cachedBlocklyTest.outputCode) {
            testCase.outputCode = cachedBlocklyTest.outputCode
            outputAce.setValue(cachedBlocklyTest.outputCode)
            outputAce.clearSelection()
          }
          return
        } else {
          console.log('Must instantiate Blockly', testCase.name, 'with new state', newBlocklyState, 'because cached is', cachedBlocklyTest?.state, cachedBlocklyTest?.inputState, 'and loaded is', testBlockly.loaded, 'and focused is', testCase.focused)
        }
        if (!testBlockly.loaded) {
          testBlockly.load()
        }
        // Input ace -> Blockly
        testCase.inputBlocklyState = newBlocklyState
        blocklyUtils.loadBlocklyState(newBlocklyState, testBlockly.workspace)
      }
      inputAce.getSession().getDocument().on('change', onAceChange)
      onAceChange()
      if (testCase.status) {
        testContainer.addClass(testCase.status)
        testContainer.find('.test-status').text(`${testCase.status} - ${testCase.reason}`)
      }
    }

    runCodeToBlocks ({ testCase, code, codeLanguage, errorDiv, prepData, prepDataError }) {
      try {
        const newBlocklyState = codeToBlocks({ code, codeLanguage, prepData })
        if (!prepDataError) {
          $(errorDiv).text('').addClass('hide')
        }
        if (newBlocklyState) {
          console.log('codeToBlocks produced new blockly state for', testCase.name, 'as', newBlocklyState)
          return newBlocklyState
        }
      } catch (err) {
        console.error('codeToBlocks errored out:', err)
        const errMessage = (prepDataError ? prepDataError.message + '\n' : '') + err.message
        $(errorDiv).text(errMessage).removeClass('hide')
        return null
      }
    }

    afterRender () {
      super.afterRender()
    }

    configureAce (ace, codeLanguage) {
      const aceSession = ace.getSession()
      const aceDoc = aceSession.getDocument()
      aceSession.setUseWorker(false)
      aceSession.setMode(aceUtils.aceEditModes[codeLanguage])
      aceSession.setWrapLimitRange(null)
      aceSession.setUseWrapMode(true)
      aceSession.setNewLineMode('unix')
      aceSession.setUseSoftTabs(true)
      ace.setTheme('ace/theme/textmate')
      ace.setDisplayIndentGuides(false)
      ace.setShowPrintMargin(false)
      ace.setShowInvisibles(false)
      ace.setBehavioursEnabled(false)
      ace.setAnimatedScroll(true)
      ace.setShowFoldWidgets(false)
      ace.$blockScrolling = Infinity
    }

    destroy () {
      for (const blocklyWorkspace of this.blocklyWorkspaces) {
        blocklyWorkspace.dispose()
      }
      return super.destroy()
    }
  }

  BlockTestingView.initClass()
  return BlockTestingView
})())

testCases.push({
  name: 'Simple',
  code: `
hero.moveRight()
hero.moveDown()
hero.moveRight()`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Variable',
  code: `
var greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'var / let / const',
  code: `
var g1 = "Hello"
let g2 = "World"
const g3 = " "
g2 = g1 + g2 + g3
hero.say(g2)
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Multiple blocks of blocks with line breaks',
  code: `
hero.say("Hi")
hero.say("Mom")

hero.say("I'm")
hero.say("so")
hero.say("hungry")


hero.say("Pizza?")
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Comment lines',
  code: `
// Defend against "Brak" and "Treg"!
// You must attack small ogres twice.

hero.moveRight();
hero.attack("Brak");
hero.attack("Brak");
hero.moveRight();
hero.attack("Treg");
hero.attack("Treg");`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'While loops',
  code: `
while (true) {
    hero.moveRight()
    hero.moveDown()

    hero.moveLeft()
    hero.moveUp()
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Break/continue',
  code: `
while (true) {
    hero.moveRight()

    if (hero.health <= 25) {
        break
    }

    if (hero.health < hero.maxHealth * 2) {
        continue
    }

    hero.moveLeft()
}

while (hero.health !== 'potato') {
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'If/else',
  code: `
if (hero.health < 25) {
    hero.say("I'm dying!")
} else {
    hero.say("I'm fine!")
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'If/else if/else',
  code: `
if (hero.health < 25) {
    hero.say("I'm dying!")
} else if (hero.health < 50) {
    hero.say("I'm hurt!")
} else {
    hero.say("I'm fine!")
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Python if/else',
  code: `
if hero.health < 25:
    hero.say("I'm dying!")
else:
    hero.say("I'm fine!")
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python if/elif/else',
  code: `
if hero.health < 25:
    hero.say("I'm dying!")
elif hero.health < 50:
    hero.say("I'm hurt!")
else:
    hero.say("I'm fine!")
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Functions',
  code: `
function foobar() {
    hero.say("foo")
    hero.say("bar")
}

foobar()

function baz(x) {
    return x * x
}

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Functions - Arrow',
  code: `
const baz = (x) => x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Arrays',
  code: `
const quux = 'I think, therefore I am'
const quuux = ['a', 2, ['c', 'd'], quux]

hero.say(quuux[quuux.length - 1][3])

const primes = [
    2,
    3,
    4,
    5,
    7
]

delete primes[2]
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Arrays - Push',
  code: `
const list = ['a', 'b']
list.push('c')
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Objects',
  code: `
const foo = {
    bar: 2,
    baz: 'quux'
}

hero.say(foo.bar)
hero.say(foo.baz)

foo['quux'] = foo.bar
foo.quux = foo.baz
foo.foo = foo
foo['foo'].foo = foo

for (const key in foo) {
    hero.say(key + ' is ' + foo[key])
}

for (const val of foo) {
    hero.say(val)
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'For loops',
  code: `
for (let i = 0; i < 10; i++) {
    hero.say(i)
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Ternary Operator',
  code: `
const foo = true ? 'bar' : 'baz'
hero.say(foo)
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Python, newlines',
  code: `
# Defeat the ogres.
# Remember that they each take two hits.

hero.attack("Rig")
hero.attack("Rig")

hero.attack("Gurt")
hero.attack("Gurt")

hero.attack("Ack")`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Variable',
  code: `
greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Comment lines',
  code: `
# Defend against "Brak" and "Treg"!
# You must attack small ogres twice.

hero.moveRight()
hero.attack("Brak")
hero.attack("Brak")
hero.moveRight()
hero.attack("Treg")
hero.attack("Treg")`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, nested comments',
  code: `
# I'm on top of the world!
while True:
    # I must go deeper.

    while True:
        # I drink your milkshake.
  `,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, While loops',
  code: `
while True:
    hero.moveRight()
    hero.moveDown()

    hero.moveLeft()
    hero.moveUp()
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Break/continue',
  code: `
while True:
    hero.moveRight()

    if hero.health <= 25:
        break

    if hero.health < hero.maxHealth * 2:
        continue

    hero.moveLeft()

while hero.health != 'potato':
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Functions',
  code: `
def foobar():
    hero.say("foo")
    hero.say("bar")

foobar()

def baz(x):
    return x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Arrays',
  code: `
quux = 'I think, therefore I am'
quuux = ['a', 2, ['c', 'd'], quux]

hero.say(quuux[quuux.length - 1][3])

primes = [
    2,
    3,
    4,
    5,
    7
]

del primes[2]
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Objects',
  code: `
foo = {
    'bar': 2,
    'baz': 'quux'
}

hero.say(foo['bar'])
hero.say(foo['baz'])

foo['quux'] = foo['bar']
foo['quux'] = foo['baz']
foo['foo'] = foo
foo['foo']['foo'] = foo

for key in foo:
    hero.say(key + ' is ' + foo[key])

for val in foo:
    hero.say(val)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Ternary Operator',
  code: `
foo = 'bar' if True else 'baz'
hero.say(foo)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Functions - Arrow',
  code: `
baz = lambda x: x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Arrays - Push',
  code: `
list = ['a', 'b']
list.append('c')
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, For loops',
  code: `
for i in range(0, 10):
    hero.say(i)

for i in range(0, 10, 2):
    hero.say(i)

for i in range(10, 0, -1):
    hero.say(i)

for i in range(10, 0, -2):
    hero.say(i)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, For loops - Array',
  code: `
for i in [1, 2, 3]:
    hero.say(i)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, For loops - Array - String',
  code: `
for i in 'abc':
    hero.say(i)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, For loops - Array - String - Break',
  code: `
for i in 'abc':
    hero.say(i)
    break

for i in 'abc':
    hero.say(i)
    continue
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'D',
  code: `
// Grab all the gems using your movement commands.

hero.moveRight();
d
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Raw',
  code: `
const foo = {
    bar: 2,
    baz: 'quux'
}

var x = 10
hero.attack(x)
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'While loop with comment',
  code: `
while (true) {
    // Add some code to do ANYTHING
    ` + `
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Intro comment section entry points',
  code: `
// This has some comments at the top
// Those comments should not produce an entry point

var foo = "bar"
// Now, young Jedi, use the Code Here


while (true) {
    // Add some code to do ANYTHING
    ` + `
}
`,
  codeLanguage: 'javascript'
})

propertyEntryGroups = {
  Deflector: {
    props: [
      { args: [{ type: 'object', name: 'target' }], type: 'function', name: 'bash', owner: 'this', ownerName: 'hero' },
      { owner: 'this', type: 'function', name: 'shield', ownerName: 'hero' }
    ]
  },
  'Sword of the Temple Guard': {
    props: [
      { returns: { type: 'number' }, args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'attack', owner: 'this', ownerName: 'hero' },
      { type: 'number', name: 'attackDamage', owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'powerUp', owner: 'this', ownerName: 'hero' }]
  },
  'Twilight Glasses': {
    props: [
      { args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'distanceTo', owner: 'this', ownerName: 'hero' },
      {
        returns: { type: 'array' },
        args: [
          { type: 'string', name: 'type' },
          { type: 'array', name: 'units' }
        ],
        type: 'function',
        name: 'findByType',
        owner: 'this',
        ownerName: 'hero'
      },
      { returns: { type: 'array' }, name: 'findEnemies', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findFriends', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findItems', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearest', type: 'function', args: [{ name: 'units', type: 'array' }], owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearestEnemy', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearestItem', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findEnemyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findFriendlyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, type: 'function', name: 'findHazards', owner: 'this', ownerName: 'hero' },
      {
        name: 'isPathClear',
        type: 'function',
        returns: { type: 'boolean' },
        args: [
          { name: 'start', type: 'object' },
          { name: 'end', type: 'object' }
        ],
        owner: 'this',
        ownerName: 'hero'
      }]
  },
  'Sapphire Sense Stone': {
    props: [
      { returns: { type: 'boolean' }, owner: 'this', args: [{ type: 'string', name: 'effect' }], type: 'function', name: 'hasEffect', ownerName: 'hero' },
      { name: 'health', type: 'number', owner: 'this', ownerName: 'hero' },
      { name: 'maxHealth', type: 'number', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'pos', owner: 'this', ownerName: 'hero' },
      { type: 'number', name: 'gold', owner: 'this', ownerName: 'hero' },
      { name: 'target', type: 'object', owner: 'this', ownerName: 'hero' },
      { name: 'targetPos', type: 'object', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'velocity', owner: 'this', ownerName: 'hero' }]
  },
  "Emperor's Gloves": {
    props: [
      {
        returns: { type: 'boolean' },
        args: [
          { type: 'string', name: 'spell' },
          { type: 'object', name: 'target' }
        ],
        type: 'function',
        name: 'canCast',
        owner: 'this',
        ownerName: 'hero'
      },
      {
        args: [
          { type: 'string', name: 'spell' },
          { type: 'object', name: 'target' }
        ],
        type: 'function',
        name: 'cast',
        owner: 'this',
        ownerName: 'hero'
      },
      { args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'castChainLightning', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'spells', owner: 'this', ownerName: 'hero' }]
  },
  'Gilt Wristwatch': {
    props: [
      { name: 'findCooldown', type: 'function', args: [{ name: 'action', type: 'string' }], returns: { type: 'number' }, owner: 'this', ownerName: 'hero' },
      { name: 'isReady', type: 'function', returns: { type: 'boolean' }, args: [{ name: 'action', type: 'string' }], owner: 'this', ownerName: 'hero' },
      { type: 'Number', name: 'time', owner: 'this', ownerName: 'hero' },
      { name: 'wait', type: 'function', args: [{ name: 'duration', type: 'number', default: '' }], owner: 'this', ownerName: 'hero' }]
  },
  'Caltrop Belt': {
    props: [
      { owner: 'this', type: 'array', name: 'buildTypes', ownerName: 'hero' },
      {
        owner: 'this',
        args: [
          { default: '', type: 'string', name: 'buildType' },
          { type: 'number', name: 'x' },
          { type: 'number', name: 'y' }
        ],
        type: 'function',
        name: 'buildXY',
        ownerName: 'hero'
      }]
  },
  'Simple Boots': {
    props: [
      { type: 'function', name: 'moveDown', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveLeft', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveRight', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveUp', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveTo', args: [{ name: 'point', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' }]
  },
  'Ring of Earth': {
    props: [
      { name: 'castEarthskin', type: 'function', args: [{ name: 'target', type: 'object', default: '' }], owner: 'this', ownerName: 'hero' }]
  },
  'Boss Star V': {
    props: [
      { owner: 'this', type: 'array', name: 'built', ownerName: 'hero' },
      {
        name: 'command',
        type: 'function',
        args: [
          { name: 'minion', type: 'object' },
          { name: 'method', type: 'string' },
          { name: 'arg1', type: 'object', optional: true },
          { name: 'arg2', type: 'object', optional: true }
        ],
        owner: 'this',
        ownerName: 'hero'
      },
      { name: 'commandableMethods', type: 'array', owner: 'this', ownerName: 'hero' },
      { name: 'commandableTypes', type: 'array', owner: 'this', ownerName: 'hero' },
      { args: [{ default: '', type: 'string', name: 'buildType' }], returns: { type: 'number' }, type: 'function', name: 'costOf', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, owner: 'this', args: [{ default: '', type: 'string', name: 'summonType' }], type: 'function', name: 'summon', ownerName: 'hero' }]
  },
  "Master's Flags": {
    props: [
      { returns: { type: 'object' }, name: 'addFlag', type: 'function', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'string', name: 'color' }], returns: { type: 'object' }, type: 'function', name: 'findFlag', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, type: 'function', name: 'findFlags', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'flag', name: 'flag' }], type: 'function', name: 'pickUpFlag', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'flag', name: 'flag' }], type: 'function', name: 'removeFlag', owner: 'this', ownerName: 'hero' }]
  },
  Pugicorn: {
    props: [
      { name: 'pet', type: 'object', owner: 'this', ownerName: 'hero' },
      { owner: 'snippets', args: [{ type: 'object', name: 'enemy' }], type: 'snippet', name: 'pet.charm(enemy)' },
      { args: [{ type: 'object', name: 'item' }], owner: 'snippets', type: 'snippet', name: 'pet.fetch(item)' },
      { owner: 'snippets', returns: { type: 'object' }, args: [{ type: 'string', name: 'type' }], type: 'snippet', name: 'pet.findNearestByType(type)' },
      { owner: 'snippets', args: [{ type: 'string', name: 'ability' }], returns: { type: 'boolean' }, type: 'snippet', name: 'pet.isReady(ability)' },
      {
        owner: 'snippets',
        name: 'pet.moveXY(x, y)',
        type: 'snippet',
        args: [
          { name: 'x', type: 'number', default: '' },
          { name: 'y', type: 'number', default: '' }
        ]
      },
      {
        owner: 'snippets',
        args: [
          { type: 'string', name: 'eventType' },
          { type: 'function', name: 'handler' }
        ],
        type: 'snippet',
        name: 'pet.on(eventType, handler)'
      },
      { owner: 'snippets', name: 'pet.say(message)', type: 'snippet', args: [{ name: 'message', type: 'string', default: '' }] },
      { owner: 'snippets', type: 'snippet', name: 'pet.trick()' }]
  },
  'Programmaticon V': {
    props: [
      { name: 'debug', type: 'function', owner: 'this', ownerName: 'hero' },
      { owner: 'snippets', type: 'snippet', name: 'arrays' },
      { owner: 'snippets', codeLanguages: ['javascript', 'python', 'coffeescript', 'lua', 'io'], type: 'snippet', name: 'break' },
      { owner: 'snippets', codeLanguages: ['javascript', 'python', 'coffeescript', 'lua', 'io'], type: 'snippet', name: 'continue' },
      { owner: 'snippets', type: 'snippet', name: 'else' },
      { owner: 'snippets', type: 'snippet', name: 'for-in-loop' },
      { owner: 'snippets', type: 'snippet', name: 'for-loop' },
      { owner: 'snippets', type: 'snippet', name: 'functions' },
      { owner: 'snippets', type: 'snippet', name: 'if/else' },
      { owner: 'snippets', codeLanguages: ['python', 'coffeescript'], type: 'snippet', name: 'list comprehensions' },
      { owner: 'snippets', type: 'snippet', name: 'objects' },
      { owner: 'snippets', type: 'snippet', name: 'while-loop' },
      { owner: 'snippets', type: 'snippet', name: 'while-true loop' }]
  }
}

function hashString (str) {
  // djb2 algorithm; hash * 33 + c
  return Array.from(str).reduce((hash, char) => ((hash << 5) + hash) + char.charCodeAt(0), 5381)
}
