// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RelatedAchievementsView
require('app/styles/editor/related-achievements.sass')
const CocoView = require('views/core/CocoView')
const template = require('app/templates/editor/level/related-achievements')
const RelatedAchievementsCollection = require('collections/RelatedAchievementsCollection')
const Achievement = require('models/Achievement')
const NewAchievementModal = require('./modals/NewAchievementModal')

module.exports = (RelatedAchievementsView = (function () {
  RelatedAchievementsView = class RelatedAchievementsView extends CocoView {
    static initClass () {
      this.prototype.id = 'related-achievements-view'
      this.prototype.template = template
      this.prototype.className = 'tab-pane'

      this.prototype.events =
        { 'click #new-achievement-button': 'makeNewAchievement' }

      this.prototype.subscriptions =
        { 'editor:view-switched': 'onViewSwitched' }
    }

    constructor (options) {
      super(options)
      this.level = options.level
      this.relatedID = this.level.get('original')
      this.achievements = new RelatedAchievementsCollection(this.relatedID)
    }

    loadAchievements () {
      if (this.loadingAchievements) { return }
      this.supermodel.loadCollection(this.achievements, 'achievements')
      this.loadingAchievements = true
      return this.render()
    }

    onNewAchievementSaved (achievement) {}
    // We actually open the new tab in NewAchievementModal, so we don't replace this window.
    // url = '/editor/achievement/' + (achievement.get('slug') or achievement.id)
    // application.router.navigate(, {trigger: true})  # Let's open a new tab instead.

    makeNewAchievement () {
      const modal = new NewAchievementModal({ model: Achievement, modelLabel: 'Achievement', level: this.level })
      modal.once('model-created', this.onNewAchievementSaved)
      return this.openModalView(modal)
    }

    onViewSwitched (e) {
      // Lazily load.
      if (e.targetURL !== '#related-achievements-view') { return }
      return this.loadAchievements()
    }
  }
  RelatedAchievementsView.initClass()
  return RelatedAchievementsView
})())
