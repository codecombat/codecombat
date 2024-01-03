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

const tempMethods = {"Deflector":{"props":[{"args":[{"type":"object","name":"target"}],"type":"function","name":"bash","owner":"this","ownerName":"hero"},{"owner":"this","type":"function","name":"shield","ownerName":"hero"}]},"Sword of the Temple Guard":{"props":[{"args":[{"default":"","type":"object","name":"target"}],"type":"function","name":"attack","owner":"this","ownerName":"hero"},{"type":"number","name":"attackDamage","owner":"this","ownerName":"hero"},{"type":"function","name":"powerUp","owner":"this","ownerName":"hero"}]},"Twilight Glasses":{"props":[{"args":[{"default":"","type":"object","name":"target"}],"type":"function","name":"distanceTo","owner":"this","ownerName":"hero"},{"returns":{"type":"array"},"args":[{"type":"string","name":"type"},{"type":"array","name":"units"}],"type":"function","name":"findByType","owner":"this","ownerName":"hero"},{"name":"findEnemies","type":"function","owner":"this","ownerName":"hero"},{"name":"findFriends","type":"function","owner":"this","ownerName":"hero"},{"name":"findItems","type":"function","owner":"this","ownerName":"hero"},{"name":"findNearest","type":"function","args":[{"name":"units","type":"array"}],"owner":"this","ownerName":"hero"},{"name":"findNearestEnemy","type":"function","owner":"this","ownerName":"hero"},{"name":"findNearestItem","type":"function","owner":"this","ownerName":"hero"},{"name":"findEnemyMissiles","type":"function","owner":"this","ownerName":"hero"},{"name":"findFriendlyMissiles","type":"function","owner":"this","ownerName":"hero"},{"returns":{"type":"array"},"type":"function","name":"findHazards","owner":"this","ownerName":"hero"},{"name":"isPathClear","type":"function","returns":{"type":"boolean"},"args":[{"name":"start","type":"object"},{"name":"end","type":"object"}],"owner":"this","ownerName":"hero"}]},"Sapphire Sense Stone":{"props":[{"returns":{"type":"boolean"},"owner":"this","args":[{"type":"string","name":"effect"}],"type":"function","name":"hasEffect","ownerName":"hero"},{"name":"health","type":"number","owner":"this","ownerName":"hero"},{"name":"maxHealth","type":"number","owner":"this","ownerName":"hero"},{"type":"object","name":"pos","owner":"this","ownerName":"hero"},{"type":"number","name":"gold","owner":"this","ownerName":"hero"},{"name":"target","type":"object","owner":"this","ownerName":"hero"},{"name":"targetPos","type":"object","owner":"this","ownerName":"hero"},{"type":"object","name":"velocity","owner":"this","ownerName":"hero"}]},"Emperor's Gloves":{"props":[{"args":[{"type":"string","name":"spell"},{"type":"object","name":"target"}],"type":"function","name":"canCast","owner":"this","ownerName":"hero"},{"args":[{"type":"string","name":"spell"},{"type":"object","name":"target"}],"type":"function","name":"cast","owner":"this","ownerName":"hero"},{"args":[{"default":"","type":"object","name":"target"}],"type":"function","name":"castChainLightning","owner":"this","ownerName":"hero"},{"type":"object","name":"spells","owner":"this","ownerName":"hero"}]},"Gilt Wristwatch":{"props":[{"name":"findCooldown","type":"function","args":[{"name":"action","type":"string"}],"returns":{"type":"number"},"owner":"this","ownerName":"hero"},{"name":"isReady","type":"function","returns":{"type":"boolean"},"args":[{"name":"action","type":"string"}],"owner":"this","ownerName":"hero"},{"type":"Number","name":"time","owner":"this","ownerName":"hero"},{"name":"wait","type":"function","args":[{"name":"duration","type":"number","default":""}],"owner":"this","ownerName":"hero"}]},"Caltrop Belt":{"props":[{"owner":"this","type":"array","name":"buildTypes","ownerName":"hero"},{"owner":"this","args":[{"default":"","type":"string","name":"buildType"},{"type":"number","name":"x"},{"type":"number","name":"y"}],"type":"function","name":"buildXY","ownerName":"hero"}]},"Simple Boots":{"props":[{"type":"function","name":"moveDown","args":[{"name":"steps","type":"number","default":1}],"owner":"this","ownerName":"hero"},{"type":"function","name":"moveLeft","args":[{"name":"steps","type":"number","default":1}],"owner":"this","ownerName":"hero"},{"type":"function","name":"moveRight","args":[{"name":"steps","type":"number","default":1}],"owner":"this","ownerName":"hero"},{"shortDescription":"short about move\\ntada","type":"function","name":"moveUp","args":[{"name":"steps","type":"number","default":1}],"owner":"this","ownerName":"hero"}]},"Ring of Earth":{"props":[{"name":"castEarthskin","type":"function","args":[{"name":"target","type":"object","default":""}],"owner":"this","ownerName":"hero"}]},"Boss Star V":{"props":[{"owner":"this","type":"array","name":"built","ownerName":"hero"},{"name":"command","type":"function","args":[{"name":"minion","type":"object"},{"name":"method","type":"string"},{"name":"arg1","type":"object","optional":true},{"name":"arg2","type":"object","optional":true}],"owner":"this","ownerName":"hero"},{"name":"commandableMethods","type":"array","owner":"this","ownerName":"hero"},{"name":"commandableTypes","type":"array","owner":"this","ownerName":"hero"},{"args":[{"default":"","type":"string","name":"buildType"}],"returns":{"type":"number"},"type":"function","name":"costOf","owner":"this","ownerName":"hero"},{"owner":"this","args":[{"default":"","type":"string","name":"summonType"}],"type":"function","name":"summon","ownerName":"hero"}]},"Master's Flags":{"props":[{"name":"addFlag","type":"function","owner":"this","ownerName":"hero"},{"args":[{"type":"string","name":"color"}],"returns":{"type":"object"},"type":"function","name":"findFlag","owner":"this","ownerName":"hero"},{"returns":{"type":"array"},"type":"function","name":"findFlags","owner":"this","ownerName":"hero"},{"args":[{"type":"flag","name":"flag"}],"type":"function","name":"pickUpFlag","owner":"this","ownerName":"hero"},{"args":[{"type":"flag","name":"flag"}],"type":"function","name":"removeFlag","owner":"this","ownerName":"hero"}]},"Pugicorn":{"props":[{"name":"pet","type":"object","owner":"this","ownerName":"hero"},{"owner":"snippets","args":[{"type":"object","name":"enemy"}],"type":"snippet","name":"pet.charm(enemy)"},{"args":[{"type":"object","name":"item"}],"owner":"snippets","type":"snippet","name":"pet.fetch(item)"},{"owner":"snippets","returns":{"type":"object"},"args":[{"type":"string","name":"type"}],"type":"snippet","name":"pet.findNearestByType(type)"},{"owner":"snippets","args":[{"type":"string","name":"ability"}],"returns":{"type":"boolean"},"type":"snippet","name":"pet.isReady(ability)"},{"owner":"snippets","name":"pet.moveXY(x, y)","type":"snippet","args":[{"name":"x","type":"number","default":""},{"name":"y","type":"number","default":""}]},{"owner":"snippets","args":[{"type":"string","name":"eventType"},{"type":"function","name":"handler"}],"type":"snippet","name":"pet.on(eventType, handler)"},{"owner":"snippets","name":"pet.say(message)","type":"snippet","args":[{"name":"message","type":"string","default":""}]},{"owner":"snippets","type":"snippet","name":"pet.trick()"}]},"Programmaticon V":{"props":[{"name":"debug","type":"function","owner":"this","ownerName":"hero"},{"owner":"snippets","type":"snippet","name":"arrays"},{"owner":"snippets","codeLanguages":["javascript","python","coffeescript","lua","io"],"type":"snippet","name":"break"},{"owner":"snippets","codeLanguages":["javascript","python","coffeescript","lua","io"],"type":"snippet","name":"continue"},{"owner":"snippets","type":"snippet","name":"else"},{"owner":"snippets","type":"snippet","name":"for-in-loop"},{"owner":"snippets","type":"snippet","name":"for-loop"},{"owner":"snippets","type":"snippet","name":"functions"},{"owner":"snippets","type":"snippet","name":"if/else"},{"owner":"snippets","codeLanguages":["python","coffeescript"],"type":"snippet","name":"list comprehensions"},{"owner":"snippets","type":"snippet","name":"objects"},{"owner":"snippets","type":"snippet","name":"while-loop"},{"owner":"snippets","type":"snippet","name":"while-true loop"}]}}

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
      this.render()

      console.log('gotta add blockly')
      const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups: tempMethods, codeLanguage: 'javascript' })
      console.log(toolbox)
      blocklyUtils.registerBlocklyTheme()
      const targetDiv = this.$('#blockly-container')
      console.log(targetDiv)
      const blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox })
      console.log(blocklyOptions)
      this.blockly = Blockly.inject(targetDiv[0], blocklyOptions)
      console.log(this.blockly)
      blocklyUtils.initializeBlocklyTooltips()
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
