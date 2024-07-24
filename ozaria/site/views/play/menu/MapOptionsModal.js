let MapOptionsModal
const utils = require('core/utils')

const submenuViews = []
require('app/styles/play/menu/game-menu-modal.sass')

const OptionsView = require('ozaria/site/views/play/menu/OptionsView')
submenuViews.push(OptionsView)

const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/menu/game-menu-modal')

require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

module.exports = (MapOptionsModal = (function () {
  MapOptionsModal = class MapOptionsModal extends ModalView {
    static initClass () {
      this.prototype.className = 'modal fade play-modal'
      this.prototype.template = template
      this.prototype.id = 'game-menu-modal'
      this.prototype.instant = true

      this.prototype.events = {
        'click .done-button': 'hide',
        'click #close-modal': 'hide',
      }
    }

    getRenderData (context) {
      if (context == null) { context = {} }
      context = super.getRenderData(context)
      const submenus = ['my-code', 'options']
      context.submenus = submenus
      context.isCodeCombat = utils.isCodeCombat
      return context
    }

    afterRender () {
      super.afterRender()
      for (const SubmenuView of Array.from(submenuViews)) { this.insertSubView(new SubmenuView(this.options)) }
      const firstView = this.subviews.options_view
      if (firstView) {
        firstView.$el.addClass('active')
      }
      this.playSound('game-menu-open')
      return this.$el.find('.nano:visible').nanoScroller()
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
  }
  MapOptionsModal.initClass()
  return MapOptionsModal
})())
