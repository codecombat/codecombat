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
const { propertyEntryGroups, initialTestCases } = require('views/artisans/block-testing-data')

const testCases = _.cloneDeep(initialTestCases)
let levelTestsAdded = false
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
          let solutionCodeLanguageIndex = 0
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
        const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: testCase.codeLanguage, codeFormat: 'blocks-text' })
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
                .replace(/(while|if|for|function) \(/g, '$1(') // Ignore space between keyword and opening parenthesis
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
        const toolboxJS = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: 'javascript', codeFormat: 'blocks-text' })
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

function hashString (str) {
  // djb2 algorithm; hash * 33 + c
  return Array.from(str).reduce((hash, char) => ((hash << 5) + hash) + char.charCodeAt(0), 5381)
}
