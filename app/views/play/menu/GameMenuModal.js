/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GameMenuModal
const utils = require('core/utils')

const submenuViews = []
require('app/styles/play/menu/game-menu-modal.sass')

if (utils.isOzaria) {
  submenuViews.push(require('ozaria/site/views/play/menu/OptionsView'))
} else {
  submenuViews.push(require('views/play/menu/MyCodeView'))
  submenuViews.push(require('views/play/menu/OptionsView'))
}

const ModalView = require('views/core/ModalView')
const CourseVideosModal = require('views/play/level/modal/CourseVideosModal')
const CreateAccountModal = require('views/core/CreateAccountModal')
const template = require('app/templates/play/menu/game-menu-modal')

module.exports = (GameMenuModal = (function () {
  GameMenuModal = class GameMenuModal extends ModalView {
    static initClass () {
      this.prototype.className = 'modal fade play-modal'
      this.prototype.template = template
      this.prototype.id = 'game-menu-modal'
      this.prototype.instant = true

      this.prototype.events = {
        'click .done-button': 'hide',
        'click #close-modal': 'hide',
        'change input.select': 'onSelectionChanged',
        'shown.bs.tab #game-menu-nav a': 'onTabShown',
        'click #change-hero-tab' () { return this.trigger('change-hero') },
        'click .auth-tab': 'onClickSignupButton',
        'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal',
        'click .hints-button': 'onClickHintsButton',
        'click .course-videos-button': 'onClickCourseVideosButton',
      }
    }

    constructor (options) {
      let left, left1
      super(options)
      this.level = this.options.level
      this.options.levelID = this.options.level.get('slug')
      this.options.startingSessionHeroConfig = $.extend({}, true, ((left = this.options.session.get('heroConfig')) != null ? left : {}))
      Backbone.Mediator.publish('music-player:enter-menu', { terrain: (left1 = this.options.level.get('terrain', true)) != null ? left1 : 'Dungeon' })
    }

    getRenderData (context) {
      if (context == null) { context = {} }
      context = super.getRenderData(context)
      const submenus = ['my-code', 'options']
      context.showTab = this.options.showTab != null ? this.options.showTab : submenus[0]
      context.iconMap = {
        'my-code': 'list-alt',
        options: 'cog',
        'save-load': 'floppy-disk',
      }
      context.submenus = submenus
      context.isCodeCombat = utils.isCodeCombat
      return context
    }

    showsCourseVideos () {
      return me.isStudent() && this.options.courseID === utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE
    }

    showsChooseHero () {
      return this.level.usesSessionHeroThangType()
    }

    afterRender () {
      super.afterRender()
      for (const SubmenuView of Array.from(submenuViews)) { this.insertSubView(new SubmenuView(this.options)) }
      const firstView = this.subviews.my_code_view
      firstView.$el.addClass('active')
      if (typeof firstView.onShown === 'function') {
        firstView.onShown()
      }
      this.playSound('game-menu-open')
      return this.$el.find('.nano:visible').nanoScroller()
    }

    onTabShown (e) {
      this.playSound('game-menu-tab-switch')
      const shownSubviewKey = e.target.hash.substring(1).replace(/-/g, '_')
      if (typeof this.subviews[shownSubviewKey].onShown === 'function') {
        this.subviews[shownSubviewKey].onShown()
      }
      return (() => {
        const result = []
        for (const subviewKey in this.subviews) {
          const subview = this.subviews[subviewKey]
          if (subviewKey !== shownSubviewKey) {
            result.push((typeof subview.onHidden === 'function' ? subview.onHidden() : undefined))
          }
        }
        return result
      })()
    }

    onHidden () {
      super.onHidden()
      for (const subviewKey in this.subviews) {
        const subview = this.subviews[subviewKey]; if (typeof subview.onHidden === 'function') {
          subview.onHidden()
        }
      }
      this.playSound('game-menu-close')
      return Backbone.Mediator.publish('music-player:exit-menu', {})
    }

    onClickHintsButton () {
      if (!this.options.hintsState) { return }
      this.options.hintsState.set('hidden', !this.options.hintsState.get('hidden'))
      window.tracker?.trackEvent('Hints Clicked', { category: 'Students', levelSlug: this.options.level.get('slug'), hintCount: this.options.hintsState.get('hints')?.length || 0 })
      const event = { state: this.options.hintsState.get('hidden') }
      this.hide()
      Backbone.Mediator.publish('level:hints-button', event)
    }

    onClickCourseVideosButton (e) {
      this.openModalView(new CourseVideosModal({ courseInstanceID: this.options.courseInstanceID, courseID: this.options.courseID }))
    }

    openCreateAccountModal (e) {
      e.stopPropagation()
      return this.openModalView(new CreateAccountModal())
    }

    onClickSignupButton (e) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Started Signup', { category: 'Play Level', label: 'Game Menu', level: this.options.levelID })
      }
      // TODO: Default already seems to be prevented.  Need to be explicit?
      e.preventDefault()
      return this.openModalView(new CreateAccountModal())
    }
  }
  GameMenuModal.initClass()
  return GameMenuModal
})())
