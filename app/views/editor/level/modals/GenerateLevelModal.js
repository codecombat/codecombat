// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GenerateLevelModal
require('app/styles/editor/level/modal/generate-level-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/level/modal/generate-level-modal')

const { presetSizes } = require('app/lib/terrain-generation')

module.exports = (GenerateLevelModal = (function () {
  GenerateLevelModal = class GenerateLevelModal extends ModalView {
    static initClass () {
      this.prototype.id = 'generate-level-modal'
      this.prototype.template = template
      this.prototype.plain = true
      this.prototype.modalWidthPercent = 90

      this.prototype.events =
        { 'click .choose-option': 'onGenerate' }
    }

    constructor (options) {
      super(options)
      this.presetSizes = _.omit(presetSizes, (v, k) => !/junior/.test(k))
    }

    onGenerate (e) {
      const target = $(e.target).closest('.choose-option')
      const size = target.attr('data-preset-size')
      console.log('size', size, 'target', target)
      Backbone.Mediator.publish('editor:generate-random-level', { size })
      this.hide()
    }

    onHidden () {
      if (this.reloadOnClose) {
        location.reload()
      }
    }
  }
  GenerateLevelModal.initClass()
  return GenerateLevelModal
})())
