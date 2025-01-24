// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SaveCampaignModal
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/campaign/save-campaign-modal')
const DeltaView = require('views/editor/DeltaView')

const CHUNK_SAVE_SIZE = 50

module.exports = (SaveCampaignModal = (function () {
  SaveCampaignModal = class SaveCampaignModal extends ModalView {
    static initClass () {
      this.prototype.id = 'save-campaign-modal'
      this.prototype.template = template
      this.prototype.plain = true

      this.prototype.events =
        { 'click #save-button': 'onClickSaveButton' }
    }

    constructor (options, modelsToSave) {
      super(options)
      this.modelsToSave = modelsToSave
    }

    afterRender () {
      this.$el.find('.delta-view').each((i, el) => {
        const $el = $(el)
        const model = this.modelsToSave.find({ id: $el.data('model-id') })
        const deltaView = new DeltaView({ model })
        return this.insertSubView(deltaView, $el)
      })
      return super.afterRender()
    }

    async onClickSaveButton () {
      this.showLoading()
      const modelsBeingSaved = (Array.from(this.modelsToSave.models).map((model) => model.patch()))
      const totalModels = modelsBeingSaved.length
      let savedCount = 0

      const loadingScreen = this.$el.find('.loading-screen')
      try {
        for (let i = 0; i < modelsBeingSaved.length; i += CHUNK_SAVE_SIZE) {
          const chunkPromises = modelsBeingSaved.slice(i, i + CHUNK_SAVE_SIZE)
          // Update loading message
          const message = `Saving models... ${savedCount}/${totalModels} (${Math.round(savedCount / totalModels * 100)}%)`
          console.info(message)
          const percentage = Math.round((savedCount / totalModels) * 100)
          loadingScreen.find('.progress-bar').css('width', `${percentage}%`)
          await Promise.all(chunkPromises)
          savedCount += chunkPromises.length
        }
        document.location.reload()
      } catch (error) {
        console.error('Error saving models:', error)
        // You might want to show an error message to the user here
        this.hideLoading()
      }
    }
  }
  SaveCampaignModal.initClass()
  return SaveCampaignModal
})())
