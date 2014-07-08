View = require 'views/kinds/RootView'
template = require 'templates/editor/thang/sprite_parser_test'
SpriteParser = require 'lib/sprites/SpriteParser'
mixed_samples = require 'lib/sprites/parser_samples'
samples = require 'lib/sprites/parser_samples_artillery'
ThangType = require 'models/ThangType'

module.exports = class SpriteParserTestView extends View
  id: 'sprite-parser-test-view'
  template: template

  afterRender: ->
    @parse samples

  parse: (samples) ->
    thangType = new ThangType()
    for sample in _.shuffle samples
      parser = new SpriteParser(thangType)
      parser.parse(sample)
    console.log 'thang type is now', thangType
    console.log JSON.stringify(thangType).length
#    console.log JSON.stringify(thangType.attributes.raw.animations.tharin_defend.tweens)
