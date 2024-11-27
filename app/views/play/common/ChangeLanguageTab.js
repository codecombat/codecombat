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
const { CODE_FORMAT_ALL, CODE_FORMAT_BLOCKS, CODE_FORMAT_IPAD, CODE_FORMAT_TEXT, JUNIOR_LANGUAGES } = require('core/constants')

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
      this.isJunior = this.options.level?.get('product') === 'codecombat-junior' || this.options.campaign?.get('slug') === 'junior'
      this.classroomAceConfig = options.classroomAceConfig
      this.utils = utils
      this.codeLanguageObject = utils.getCodeLanguages()
      this.codeFormatObject = utils.getCodeFormats()
      const defaultCodeFormat = 'text-code'
      this.codeFormat = this.options.codeFormat || me.get('aceConfig')?.codeFormat || defaultCodeFormat
      if (this.isJunior && options.level?.get('slug') === 'the-gem') {
        // let's default to blocks-text for the-gem (first level) in junior so that users can see the blocks
        const blockFormat = 'blocks-icons'
        if (me.isStudent()) {
          if (this.classroomAceConfig?.codeFormats?.includes(blockFormat)) {
            this.codeFormat = blockFormat
          }
        } else {
          this.codeFormat = blockFormat
        }
      }
      this.codeLanguage = this.options?.session?.get('codeLanguage') || me.get('aceConfig')?.language || 'python'

      this.updateCodeFormatList()
      this.updateCodeLanguageList()
    }

    afterRender () {
      super.afterRender()

      this.buildCodeLanguages()
      this.buildCodeFormats()
    }

    getRenderData (context) {
      if (context == null) { context = {} }
      context = super.getRenderData(context)
      context.codeLanguages = Object.values(this.codeLanguageObject)
      context.codeLanguage = this.codeLanguage
      context.codeFormats = Object.values(this.codeFormatObject)
      context.codeFormat = this.codeFormat
      return context
    }

    updateCodeFormatList () {
      for (const format in this.codeFormatObject) {
        this.codeFormatObject[format].disabled = false
      }
      let onlyText = true
      const classroomFormats = this.options?.classroomAceConfig?.codeFormats
      // non-junior should only have text-code
      if (this.isJunior) {
        if (JUNIOR_LANGUAGES.includes(this.codeLanguage)) {
          if (me.isStudent()) {
            if (classroomFormats?.length) {
              if (classroomFormats.length > 1 || classroomFormats[0] !== 'text-code') {
                onlyText = false
              }
            } else {
              onlyText = false
            }
          } else {
            onlyText = false
          }
        }
      }

      if (onlyText) {
        CODE_FORMAT_BLOCKS.forEach(format => {
          this.codeFormatObject[format].disabled = true
          this.codeFormatObject[format].reason = $.i18n.t('choose_hero.code_format_not_supported')
        })
      } else {
        if (me.isStudent() && classroomFormats?.length) {
          CODE_FORMAT_ALL.forEach(format => {
            if (!classroomFormats.includes(format)) {
              this.codeFormatObject[format].disabled = true
              this.codeFormatObject[format].reason = $.i18n.t('choose_hero.code_format_disable_by_teacher')
            }
          })
        }
      }

      // Disabling text code for Junior for mobile devices that aren't iPads.
      // iPads might have physical keyboards, which would mean we would want to let them try text code.
      if (utils.isMobile() && this.isJunior && !utils.isIPad()) {
        CODE_FORMAT_TEXT.forEach(format => {
          this.codeFormatObject[format].disabled = true
        })
        CODE_FORMAT_IPAD.forEach(format => {
          this.codeFormatObject[format].disabled = false
        })
      }

      if (this.codeFormatObject[this.codeFormat].disabled) {
        this.codeFormat = _.find(this.codeFormatObject, { disabled: false })?.id
      }
      this.renderSelectors('.code-format-form')
      this.buildCodeFormats()
    }

    updateCodeLanguageList () {
      for (const lang in this.codeLanguageObject) {
        this.codeLanguageObject[lang].disabled = false
      }
      if ((this.options?.session?.get('codeLanguage') || me.get('aceConfig')?.language) !== 'coffeescript') {
        // Not really useful to show this any more. Let's get rid of it unless they're currently using it.
        delete this.codeLanguageObject.coffeescript
      }

      let canChangeLanguage = true
      if (me.isStudent() && this.options?.level?.get('type') !== 'ladder') {
        canChangeLanguage = false
      }

      if (canChangeLanguage) {
        let premium = false
        if (me.isHomeUser() && me.isPremium()) {
          premium = true
        } else if (me.isStudent() && me.isEnrolled()) {
          premium = true
        } else if (me.isTeacher()) {
          // allow teacher to test cpp/java
          premium = true
        }
        if (!premium) {
          Array.from(['cpp', 'java']).forEach(language => {
            this.codeLanguageObject[language].disabled = true
            this.codeLanguageObject[language].reason = $.i18n.t('choose_hero.code_language_subscriber_only')
          })
        }
        if (this.codeFormat !== 'text-code') {
          Array.from(['lua', 'cpp', 'java']).forEach(language => {
            this.codeLanguageObject[language].disabled = true
            this.codeLanguageObject[language].reason = $.i18n.t('choose_hero.code_language_not_support_by_blocks')
          })
        }
      } else {
        for (const language in this.codeLanguageObject) {
          if (language !== this.codeLanguage) {
            this.codeLanguageObject[language].disabled = true
          }
        }
      }

      if (this.codeLanguageObject[this.codeLanguage].disabled) {
        this.codeLanguage = _.find(this.codeLanguageObject, { disabled: false }).id
      }
      this.renderSelectors('.code-language-form')
      this.buildCodeLanguages()
    }

    buildCodeFormats () {
      const $select = this.$el.find('#option-code-format')
      if (!utils.isMobile()) {
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
      if ($select.parent().find('.options li').length === 1) {
        $select.trigger('disable.fs')
      } else {
        $select.trigger('enable.fs')
      }
    }

    buildCodeLanguages () {
      const $select = this.$el.find('#option-code-language')
      if (!utils.isMobile()) {
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
      if ($select.parent().find('.options li').length === 1) {
        $select.trigger('disable.fs')
      } else {
        $select.trigger('enable.fs')
      }
    }

    onCodeLanguageChanged (e) {
      this.codeLanguage = this.$el.find('#option-code-language').val()
      this.codeLanguageChanged = true
      this.updateCodeFormatList()
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
      this.updateCodeLanguageList()
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
