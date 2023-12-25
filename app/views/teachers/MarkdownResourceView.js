/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MarkdownResourceView
require('app/styles/teachers/markdown-resource-view.sass')
// This is the generic view for rendering content from /app/assets/markdown

const RootView = require('views/core/RootView')
const utils = require('core/utils')
const aceUtils = require('core/aceUtils')

module.exports = (MarkdownResourceView = (function () {
  MarkdownResourceView = class MarkdownResourceView extends RootView {
    static initClass () {
      this.prototype.id = 'markdown-resource-view'
      this.prototype.template = require('app/templates/teachers/markdown-resource-view')

      this.prototype.events =
        { 'click .print-btn': 'onClickPrint' }
    }

    initialize (options, name) {
      this.name = name
      super.initialize(options)
      this.content = ''
      this.loadingData = true
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)))
      if (utils.isOzaria && (this.name === 'getting-started')) {
        this.name = 'getting-started-with-ozaria'
      }
      return $.get('/markdown/' + this.name + '.md', (data, what, who, how) => {
        if (/<!doctype html>/i.test(data)) {
          // Not found
          if (utils.isOzaria) {
            Backbone.Mediator.publish('router:navigate', { route: '/teachers/resources' })
            noty({ text: `${$.i18n.t('not_found.page_not_found')}: ${this.name}`, layout: 'center', type: 'warning', killer: false, timeout: 6000 })
            return
          }
        } else {
          const renderer = new marked.Renderer()
          const linkIDs = new Set()
          renderer.heading = (text, level) => {
            if (![2, 3].includes(level) || (_.string.startsWith(this.name, 'faq') && (level === 2))) {
              return `<h${level}>${text}</h${level}>`
            }
            let linkID = _.string.slugify(text)
            if (!linkID.replace(/(codecombat|-)/g, '') || linkIDs.has(linkID)) {
              linkID = 'header-' + linkIDs.size
            }
            linkIDs.add(linkID)
            return `<h${level}><a name='${linkID}' id='${linkID}' href='\#${linkID}'' class='header-link'></a>${text}</h${level}>` // eslint-disable-line no-useless-escape
          }

          let i = 0
          this.content = marked(data, { sanitize: false, renderer }).replace(/<\/h5/g, function () {
            if (i++ === 0) {
              return '</h5'
            } else {
              let needle
              const align = (needle = me.get('preferredLanguage'), ['he', 'ar', 'fa', 'ur'].includes(needle)) ? 'left' : 'right'
              const buttonText = $.i18n.t('teacher.back_to_top')
              return `<a class='pull-${align} btn btn-md btn-navy back-to-top' href='#top'>${buttonText}</a></h5`
            }
          })
        }

        if (this.name === 'cs1') {
          $('body').append($("<img src='https://code.org/api/hour/begin_code_combat_teacher.png' style='visibility: hidden;'>"))
        }
        this.loadingData = false
        return this.render()
      })
    }

    onClickPrint () {
      return (window.tracker != null ? window.tracker.trackEvent('Teachers Click Print Resource', { category: 'Teachers', label: this.name }) : undefined)
    }

    showTeacherLegacyNav () {
      // Hack to hide legacy dashboard navigation from faq page
      if (this.name === 'faq') {
        return false
      }
      return true
    }

    afterRender () {
      super.afterRender()
      this.$el.find('pre>code').each(function () {
        const els = $(this)
        const c = els.parent()
        let lang = els.attr('class')
        if (lang) {
          lang = lang.replace(/^lang-/, '')
        } else {
          lang = 'python'
        }

        const aceEditor = aceUtils.initializeACE(c[0], lang)
        aceEditor.setShowInvisibles(false)
        aceEditor.setBehavioursEnabled(false)
        aceEditor.setAnimatedScroll(false)
        aceEditor.$blockScrolling = Infinity
      })
      if (_.contains(location.href, '#')) {
        return _.defer(() => {
          // Remind the browser of the fragment in the URL, so it jumps to the right section.
          location.href = location.href // eslint-disable-line no-self-assign
        })
      }
    }
  }
  MarkdownResourceView.initClass()
  return MarkdownResourceView
})())

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
