// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GenerateTerrainModal
require('app/styles/editor/level/modal/generate-terrain-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/level/modal/generate-terrain-modal')
const CocoModel = require('models/CocoModel')

const { presets, presetSizes, generateThangs } = require('app/lib/terrain-generation')

module.exports = (GenerateTerrainModal = (function() {
  GenerateTerrainModal = class GenerateTerrainModal extends ModalView {
    static initClass() {
      this.prototype.id = 'generate-terrain-modal'
      this.prototype.template = template
      this.prototype.plain = true
      this.prototype.modalWidthPercent = 90
  
      this.prototype.events =
        {'click .choose-option': 'onGenerate'}
    }

    constructor(options) {
      super(options)
      this.presets = presets
      this.presetSizes = presetSizes
    }

    onRevertModel(e) {
      const id = $(e.target).val()
      CocoModel.backedUp[id].revert()
      $(e.target).closest('tr').remove()
      this.reloadOnClose = true
    }

    onGenerate(e) {
      const target = $(e.target)
      const presetType = target.attr('data-preset-type')
      const presetSize = target.attr('data-preset-size')
      const thangs = generateThangs(presetType, presetSize)
      Backbone.Mediator.publish('editor:random-terrain-generated', { thangs, terrain: presets[presetType].terrainName })
      this.hide()
    }

    onHidden() {
      if (this.reloadOnClose) {
        location.reload()
      }
    }
  }
  GenerateTerrainModal.initClass()
  return GenerateTerrainModal
})())
