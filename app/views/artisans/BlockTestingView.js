let BlockTestingView
require('app/styles/artisans/block-testing-view.sass')
const RootView = require('views/core/RootView')
const template = require('templates/artisans/block-testing-view')
const loadAetherLanguage = require('lib/loadAetherLanguage')
const blocklyUtils = require('core/blocklyUtils')
const Blockly = require('blockly')

const testCases = [
  {
    name: 'Simple',
    code: `
hero.moveRight()
hero.moveDown()
hero.moveDown()`
  },

  {
    name: 'Simple with numeric arguments',
    code: `
hero.moveRight(2)
hero.moveDown(2)
hero.moveDown(2)`
  },

  {
    name: 'Simple with string arguments',
    code: `
hero.say("Hello")
hero.say("World")`
  },

  {
    name: 'Simple with variable arguments',
    code: `
var greeting = "Hello"
hero.say(greeting)
hero.say("World")`
  }
]

module.exports = (BlockTestingView = (function () {
  BlockTestingView = class BlockTestingView extends RootView {
    static initClass () {
      this.prototype.template = template
      this.prototype.id = 'block-testing-view'

      this.prototype.events =
        { 'click #go-button': 'onClickGoButton' }

      this.prototype.testCases = testCases
    }

    constructor (options, levelSlug) {
      super(options)
      console.log('loading javascript')
      loadAetherLanguage('javascript').then((aetherLang) => {
        console.log(aetherLang, 'loaded')
        this.addBlockly()
      })
    }

    addBlockly () {
      console.log('gotta add blockly')
      const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups: {}, codeLanguage: 'javascript', level: { get: () => null } })
      blocklyUtils.registerBlocklyTheme()
      const targetDiv = this.$('#blockly-container')
      const blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox })
      this.blockly = Blockly.inject(targetDiv[0], blocklyOptions)
      blocklyUtils.initializeBlocklyTooltips()

      this.render()
    }

    afterRender () {
      super.afterRender()
    }

    onClickGoButton (event) {

    }
  }
  BlockTestingView.initClass()
  return BlockTestingView
})())
