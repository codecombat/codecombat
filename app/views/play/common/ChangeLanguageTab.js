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
const CocoView = require('views/core/CocoView')
const template = require('app/templates/play/common/change-language-tab')
const { me } = require('core/auth')
const utils = require('core/utils')

let ChangeLanguageTab
module.exports = (ChangeLanguageTab = (function () {
  ChangeLanguageTab = class ChangeLanguageTab extends CocoView {
    static initClass () {
      this.prototype.id = 'change-language-tab-view'
      this.prototype.className = 'tab-pane'
      this.prototype.template = template

      this.prototype.events = {
        'change #option-code-language': 'onCodeLanguageChanged',
        'change #option-code-format': 'onCodeFormatChanged',
      }
    }

    constructor (options) {
      super(options)
      this.session = options.session
      this.utils = utils
      this.initCodeLanguageList()
      this.classroomAceConfig = options.classroomAceConfig
      this.codeFormatList = [
        { id: 'text-code', name: `${$.i18n.t('choose_hero.text_code')} (${$.i18n.t('choose_hero.default')})` },
        { id: 'blocks-and-code', name: `${$.i18n.t('choose_hero.blocks_and_code')}` },
        { id: 'blocks-text', name: `${$.i18n.t('choose_hero.blocks_text')}` },
        { id: 'blocks-icons', name: `${$.i18n.t('choose_hero.blocks_icons')}` },
      ]
    }

    afterRender () {
      super.afterRender()

      this.buildCodeLanguages()
      this.buildCodeFormats()
    }

    getRenderData (context) {
      if (context == null) { context = {} }
      context = super.getRenderData(context)
      context.codeLanguages = this.codeLanguageList
      context.codeLanguage = this.codeLanguage = this.options?.session?.get('codeLanguage') || me.get('aceConfig')?.language || 'python'
      context.codeFormats = this.codeFormatList
      context.codeFormat = this.codeFormat = me.get('aceConfig')?.codeFormat || 'text-code'
      return context
    }

    initCodeLanguageList () {
      if (application.isIPadApp) {
        this.codeLanguageList = [
          { id: 'python', name: `Python (${$.i18n.t('choose_hero.default')})` },
          { id: 'javascript', name: 'JavaScript' }
        ]
      } else {
        this.subscriberCodeLanguageList = [
          { id: 'cpp', name: 'C++' },
          { id: 'java', name: `Java (${$.i18n.t('choose_hero.experimental')})` }
        ]
        this.codeLanguageList = [
          { id: 'python', name: `Python (${$.i18n.t('choose_hero.default')})` },
          { id: 'javascript', name: 'JavaScript' },
          { id: 'coffeescript', name: 'CoffeeScript' },
          { id: 'lua', name: 'Lua' },
          ...this.subscriberCodeLanguageList
        ]
        if (this.options?.session?.get('codeLanguage') || me.get('aceConfig')?.language !== 'coffeescript') {
          // Not really useful to show this any more. Let's get rid of it unless they're currently using it.
          this.codeLanguageList = _.filter(this.codeLanguageList, language => language.id !== 'coffeescript')
        }
      }
    }

    buildCodeFormats () {
      const $select = this.$el.find('#option-code-format')
      if (!$.browser.mobile) {
        $select.fancySelect()
      }
      $select.parent().find('.options li').each(function () {
        const formatName = $(this).text()
        const formatID = $(this).data('value')
        const blurb = $.i18n.t(`choose_hero.${formatID}_blurb`.replace(/-/g, '_'))
        if (formatName.indexOf(blurb) === -1) { // Avoid doubling blurb if this is called 2x
          return $(this).text(`${formatName} - ${blurb}`)
        }
      })
    }

    buildCodeLanguages () {
      const $select = this.$el.find('#option-code-language')
      if (!$.browser.mobile) {
        $select.fancySelect()
      }
      $select.parent().find('.options li').each(function () {
        const languageName = $(this).text()
        const languageID = $(this).data('value')
        const blurb = $.i18n.t(`choose_hero.${languageID}_blurb`)
        if (languageName.indexOf(blurb) === -1) { // Avoid doubling blurb if this is called 2x
          return $(this).text(`${languageName} - ${blurb}`)
        }
      })
    }

    onCodeLanguageChanged (e) {
      this.codeLanguage = this.$el.find('#option-code-language').val()
      this.codeLanguageChanged = true
      window.tracker?.trackEvent('Campaign changed code language', { category: 'Campaign Hero Select', codeLanguage: this.codeLanguage, levelSlug: this.options.level?.get('slug') })
      if (this.codeFormat === 'blocks-and-code' && ['python', 'javascript'].indexOf(this.codeLanguage) === -1) {
        // Blockly can't support languages like C++/Java. (Some day we'll have Lua.)
        noty({ text: `Can't show blocks and code with ${this.codeLanguage}`, layout: 'bottomCenter', type: 'error', killer: false, timeout: 3000 })
        this.$el.find('#option-code-format').val('text-code').change()
      }
    }

    onCodeFormatChanged (e) {
      this.codeFormat = this.$el.find('#option-code-format').val()
      this.codeFormatChanged = true
      window.tracker?.trackEvent('Campaign changed code format', { category: 'Campaign Hero Select', codeFormat: this.codeFormat, levelSlug: this.options.level?.get('slug') })
      if (this.codeFormat === 'blocks-and-code' && ['python', 'javascript'].indexOf(this.codeLanguage) === -1) {
        // Blockly can't support languages like C++/Java. (Some day we'll have Lua.)
        noty({ text: `Can't show blocks and code with ${this.codeLanguage}`, layout: 'bottomCenter', type: 'error', killer: false, timeout: 3000 })
        this.$el.find('#option-code-language').val('javascript').change()
      }
    }
  }
  ChangeLanguageTab.initClass()
  return ChangeLanguageTab
})())
