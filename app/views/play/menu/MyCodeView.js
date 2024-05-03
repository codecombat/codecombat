/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MyCodeView
require('app/styles/play/menu/my-code-view.sass')
const CocoView = require('views/core/CocoView')
const template = require('app/templates/play/menu/my-code-view')
const { me } = require('core/auth')

const ReloadLevelModal = require('views/play/level/modal/ReloadLevelModal')
const AskAIHelpView = require('views/play/level/AskAIHelpView').default
const ImageGalleryModal = require('views/play/level/modal/ImageGalleryModal')
const utils = require('core/utils')
const store = require('core/store')
const globalVar = require('core/globalVar')

module.exports = (MyCodeView = (function () {
  MyCodeView = class MyCodeView extends CocoView {
    static initClass () {
      this.prototype.id = 'my-code-view'
      this.prototype.className = 'tab-pane'
      this.prototype.template = template

      this.prototype.events = {
        'click .reload-code': 'onClickReloadCode',
        'click .beautify-code': 'onClickBeautifyCode',
        'click .ai-hint': 'onClickAIHint',
        'click .teacher-help': 'onClickTeacherHelp',
        'click .image-gallery': 'onClickImageGallery',
        'click .toggle-solution': 'onClickToggleSolution',
        'click .fill-solution': 'onClickFillSolution',
        'click .switch-team': 'onClickSwitchTeam',
      }
    }

    constructor (options) {
      super(options)
      this.wsBus = globalVar.application.wsBus
      this.teaching = utils.getQueryVariable('teaching')
      this.askAiBot = options.classroomAceConfig?.levelChat !== 'none'
    }

    getRenderData (c) {
      c = c || {}
      c = super.getRenderData(c)
      return c
    }

    afterRender () {
      super.afterRender()
    }

    destroy () {
      return super.destroy()
    }

    onClickReloadCode (e) {
      if (e.shiftKey) {
        return Backbone.Mediator.publish('level:restart', {})
      } else {
        return this.openModalView(new ReloadLevelModal())
      }
    }

    onClickBeautifyCode (e) {
      return Backbone.Mediator.publish('tome:spell-beautify', {})
    }

    onClickAIHint (e) {
      this.openModalView(new AskAIHelpView({}))
    }

    onClickTeacherHelp (e) {
      Backbone.Mediator.publish('websocket:asking-help', {
        msg: {
          to: this.teacherID.toString(),
          type: 'msg',
          info: {
            text: $.i18n.t('teacher.student_ask_for_help', { name: me.broadName() }),
            url: window.location.pathname
          }
        }
      })
    }

    onClickImageGallery (e) {
      this.openModalView(new ImageGalleryModal())
    }

    onClickToggleSolution (e) {
      Backbone.Mediator.publish('level:toggle-solution', {})
    }

    onClickFillSolution (e) {
      if (me.canAutoFillCode()) {
        store.dispatch('game/autoFillSolution', this.options.codeLanguage)
      }
    }

    onClickSwitchTeam (e) {
      const protocol = window.location.protocol + '//'
      const host = window.location.host
      const pathname = window.location.pathname
      let query = window.location.search
      query = query.replace(/team=[^&]*&?/, '')
      if (query) {
        if (query.endsWith('?') || query.endsWith('&')) {
          query += 'team='
        } else {
          query += '&team='
        }
      } else {
        query = '?team='
      }
      window.location.href = protocol + host + pathname + query + this.otherTeam()
    }

    otherTeam () {
      const teams = _.without(['humans', 'ogres'], this.options.team)
      return teams[0]
    }

    teacherOnline () {
      console.log('what online?', this.wsBus?.wsInfos?.friends?.[this.teacherID], this.teacherID)
      return this.wsBus?.wsInfos?.friends?.[this.teacherID]?.online
    }
  }
  MyCodeView.initClass()
  return MyCodeView
})())
