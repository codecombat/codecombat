/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
require('app/styles/play/menu/change-language-view.sass')
const { me } = require('core/auth')
const ChangeLanguageTab = require('views/play/common/ChangeLanguageTab')
const CocoView = require('views/core/CocoView')

let ChangeLanguageView
module.exports = (ChangeLanguageView = (function () {
  ChangeLanguageView = class ChangeLanguageView extends CocoView {
    static initClass () {
      this.prototype.id = 'change-language-view'
      this.prototype.className = 'tab-pane'
      this.prototype.template = require('templates/play/menu/change-language-view')
    }

    constructor (options) {
      super(options)
      this.options = options
      this.session = options.session
    }

    afterRender () {
      super.afterRender()
      this.insertSubView(this.changeLanguageTab = new ChangeLanguageTab(this.options))
    }

    onHidden () {
      this.codeLanguage = this.changeLanguageTab.codeLanguage
      this.codeFormat = this.changeLanguageTab.codeFormat
      let changed
      if (this.session) {
        if (this.session.get('codeLanguage') !== this.codeLanguage) {
          this.session.set('codeLanguage', this.codeLanguage)
          changed = true
        }
        // Backbone.Mediator.publish 'tome:change-language', language: @codeLanguage, reload: true  # We'll reload the PlayLevelView instead.
        if (changed) { this.session.patch() }
      }

      changed = false
      let codeFormatChanged = false
      const aceConfig = _.clone(me.get('aceConfig')) || {}
      if (this.codeLanguage !== aceConfig.language) {
        aceConfig.language = this.codeLanguage
        me.set('aceConfig', aceConfig)
        changed = true
      }
      if (this.codeFormat !== aceConfig.codeFormat) {
        aceConfig.codeFormat = this.codeFormat
        me.set('aceConfig', aceConfig)
        changed = true
        codeFormatChanged = true
      }

      if (changed) {
        me.patch().then(() => {
          if (codeFormatChanged) {
            return document.location.reload()
          } else {
            return Backbone.Mediator.publish('tome:change-language', { language: this.codeLanguage, reload: true })
          }
        })
      }
    }
  }
  ChangeLanguageView.initClass()
  return ChangeLanguageView
})())
