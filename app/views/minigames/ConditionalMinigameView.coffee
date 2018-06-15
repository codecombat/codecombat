RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
ConditionalMinigameComponent = require('./ConditionalMinigameComponent.vue').default

module.exports = class ConditionalMinigameView extends RootComponent
  id: 'conditional-minigame-view'
  template: template
  VueComponent: ConditionalMinigameComponent

  constructor: (options) ->
    super(options)
