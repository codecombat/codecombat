// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareLadderLinkModal
require('app/styles/play/ladder/share-ladder-link-modal.sass')
const ModalView = require('views/core/ModalView')

module.exports = (ShareLadderLinkModal = (function () {
  ShareLadderLinkModal = class ShareLadderLinkModal extends ModalView {
    static initClass () {
      this.prototype.id = 'share-ladder-link-modal'
      this.prototype.template = require('templates/play/ladder/share-ladder-link-modal')
      this.prototype.plain = false

      this.prototype.events =
        { 'click #copy-url-btn': 'onClickCopyURLButton' }
    }

    initialize ({ shareURL, eventProperties }) {
      this.shareURL = shareURL
      this.eventProperties = eventProperties
    }

    onClickCopyURLButton () {
      this.$('#copy-url-input').val(this.shareURL).select()
      this.tryCopy()
      return (window.tracker != null ? window.tracker.trackEvent('Share Ladder Link Modal - Copy URL', this.eventProperties) : undefined)
    }
  }
  ShareLadderLinkModal.initClass()
  return ShareLadderLinkModal
})())
