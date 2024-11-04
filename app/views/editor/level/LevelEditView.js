// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelEditView
require('app/styles/editor/level/documentation_tab.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/level/level-edit-view')
const Level = require('models/Level')
const LevelSystem = require('models/LevelSystem')
const LevelComponent = require('models/LevelComponent')
const LevelSystems = require('collections/LevelSystems')
const LevelComponents = require('collections/LevelComponents')
const World = require('lib/world/world')
const DocumentFiles = require('collections/DocumentFiles')
const LevelLoader = require('lib/LevelLoader')

const Achievement = require('models/Achievement')
const Campaigns = require('collections/Campaigns')
const CocoCollection = require('collections/CocoCollection')
const Course = require('models/Course')
const Campaign = require('models/Campaign')

const RevertModal = require('views/modal/RevertModal')
const GenerateTerrainModal = require('views/editor/level/modals/GenerateTerrainModal')
const GenerateLevelModal = require('views/editor/level/modals/GenerateLevelModal')
const levelGeneration = require('../../../lib/level-generation')

const ThangsTabView = require('./thangs/ThangsTabView')
const SettingsTabView = require('./settings/SettingsTabView')
const ScriptsTabView = require('./scripts/ScriptsTabView')
const ComponentsTabView = require('./components/ComponentsTabView')
const SystemsTabView = require('./systems/SystemsTabView')
const KeyThangTabView = require('./thangs/KeyThangTabView')
const TasksTabView = require('./tasks/TasksTabView')
const SaveLevelModal = require('./modals/SaveLevelModal')
const ArtisanGuideModal = require('./modals/ArtisanGuideModal')
const ForkModal = require('views/editor/ForkModal')
const SaveVersionModal = require('views/editor/modal/SaveVersionModal')
const SaveBranchModal = require('views/editor/level/modals/SaveBranchModal')
const LoadBranchModal = require('views/editor/level/modals/LoadBranchModal')
const PatchesView = require('views/editor/PatchesView')
const RelatedAchievementsView = require('views/editor/level/RelatedAchievementsView')
const VersionHistoryView = require('./modals/LevelVersionsModal')
const ComponentsDocumentationView = require('views/editor/docs/ComponentsDocumentationView')
const SystemsDocumentationView = require('views/editor/docs/SystemsDocumentationView')
const LevelFeedbackView = require('views/editor/level/LevelFeedbackView')
const storage = require('core/storage')
const utils = require('core/utils')
const loadAetherLanguage = require('lib/loadAetherLanguage')
const presenceApi = require(utils.isOzaria ? '../../../../ozaria/site/api/presence' : 'core/api/presence')
const { fetchPracticeLevels, fetchLevelStats } = require('core/api/levels')
const fetchJson = require('core/api/fetch-json')
const globalVar = require('core/globalVar')

require('vendor/scripts/coffeescript') // this is tenuous, since the LevelSession and LevelComponent models are what compile the code
require('lib/setupTreema')

// Make sure that all of our languages are loaded, so that if we try to preview the level, it will work.
require('bower_components/aether/build/html')
Promise.all(
  ['javascript', 'python', 'coffeescript', 'lua'].map(
    loadAetherLanguage
  )
)
require('lib/game-libraries')

module.exports = (LevelEditView = (function () {
  LevelEditView = class LevelEditView extends RootView {
    static initClass () {
      this.prototype.id = 'editor-level-view'
      this.prototype.className = 'editor'
      this.prototype.template = template
      this.prototype.cache = false

      this.prototype.events = {
        'click #play-button': 'onPlayLevel',
        'click .play-with-team-button': 'onPlayLevel',
        'click .play-with-team-parent': 'onPlayLevelTeamSelect',
        'click .play-classroom-level': 'onPlayLevel',
        'click #commit-level-start-button': 'startCommittingLevel',
        'click li:not(.disabled) > #fork-start-button': 'startForking',
        'click #level-history-button': 'showVersionHistory',
        'click #undo-button': 'onUndo',
        'mouseenter #undo-button': 'showUndoDescription',
        'click #redo-button': 'onRedo',
        'mouseenter #redo-button': 'showRedoDescription',
        'click #patches-tab' () { return this.patchesView.load() },
        'click #components-tab' () { return this.subviews.editor_level_components_tab_view.refreshLevelThangsTreema(this.level.get('thangs')) },
        'click #artisan-guide-button': 'showArtisanGuide',
        'click #level-patch-button': 'startPatchingLevel',
        'click #level-watch-button': 'toggleWatchLevel',
        'click li:not(.disabled) > #pop-level-i18n-button': 'onPopulateI18N',
        'click a[href="#editor-level-documentation"]': 'onClickDocumentationTab',
        'click #save-branch': 'onClickSaveBranch',
        'click #load-branch': 'onClickLoadBranch',
        'mouseup .nav-tabs > li a': 'toggleTab',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal',
        'click [data-toggle="coco-modal"][data-target="editor/level/modals/GenerateTerrainModal"]': 'openGenerateTerrainModal',
        'click .generate-level-button': 'onClickGenerateLevel',
        'click .generate-practice-level-button': 'onClickGeneratePracticeLevel',
        'click .generate-all-practice-levels-button': 'onClickGenerateAllPracticeLevels',
        'click .save-all-practice-levels-button': 'onClickSaveAllPracticeLevels',
        'click .migrate-junior-button': 'onClickMigrateJunior',
      }

      this.prototype.subscriptions = {
        'editor:thang-deleted': 'onThangDeleted',
        'editor:generate-random-level': 'generateLevel',
      }

      this.prototype.shortcuts = {
        'ctrl+g': 'generateLevel',
        'ctrl+shift+g': 'generatePracticeLevel',
      }
    }

    constructor (options, levelID) {
      super(options)
      this.incrementBuildTime = this.incrementBuildTime.bind(this)
      this.checkPresence = this.checkPresence.bind(this)
      this.levelID = levelID
      this.previouslyLoadedSubviewData = {}
      this.supermodel.shouldSaveBackups = model => ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className)
      this.levelLoader = new LevelLoader({ supermodel: this.supermodel, levelID: this.levelID, headless: true, sessionless: true, loadArticles: true })
      this.level = this.levelLoader.level
      this.files = new DocumentFiles(this.levelLoader.level)
      this.supermodel.loadCollection(this.files, 'file_names')
      this.campaigns = new Campaigns()
      this.supermodel.trackRequest(this.campaigns.fetchByType('course', { data: { project: 'levels' } }))
      this.courses = new CocoCollection([], { url: '/db/course', model: Course })
      this.supermodel.loadCollection(this.courses, 'courses')
    }

    getMeta () {
      let title = $.i18n.t('editor.level_title')
      let levelName = utils.i18n(((this.level != null ? this.level.attributes : undefined) || {}), 'displayname')
      if (!levelName) { levelName = utils.i18n(((this.level != null ? this.level.attributes : undefined) || {}), 'name') }
      if (levelName) {
        title = levelName + ' - ' + title
      }
      return { title }
    }

    destroy () {
      // Currently only check presence on the level.
      // TODO: Should this system also handle other models with local backups: 'LevelComponent', 'LevelSystem', 'ThangType'
      if ((!this.level.hasLocalChanges()) && me.isAdmin()) {
        presenceApi.deletePresence({ levelOriginalId: this.level.get('original') })
      }

      clearInterval(this.timerIntervalID)
      clearInterval(this.checkPresenceIntervalID)
      return super.destroy()
    }

    showLoading ($el) {
      if ($el == null) { $el = this.$el.find('.outer-content') }
      return super.showLoading($el)
    }

    onLoaded () {
      _.defer(() => {
        this.setMeta(this.getMeta())
        this.world = this.levelLoader.world
        this.render()
        this.timerIntervalID = setInterval(this.incrementBuildTime, 1000)
        if (this.level.get('original')) {
          this.checkPresenceIntervalID = setInterval(this.checkPresence, 15000)
          this.checkPresence()
          if (me.isAdmin()) {
            presenceApi.setPresence({ levelOriginalId: this.level.get('original') })
          }
        }
      })

      const campaignCourseMap = {}
      for (const course of Array.from(this.courses.models)) { campaignCourseMap[course.get('campaignID')] = course.id }
      for (const campaign of Array.from(this.campaigns.models)) {
        const object = campaign.get('levels')
        for (const levelID in object) {
          const level = object[levelID]
          if (levelID === this.level.get('original')) {
            this.courseID = campaignCourseMap[campaign.id]
          }
        }
        if (this.courseID) { break }
      }
      if (!this.courseID && (me.isAdmin() || me.isArtisan())) {
        // Give it a fake course ID so we can test it in course mode before it's in a course.
        this.courseID = '560f1a9f22961295f9427742'
      }
      this.getLevelCompletionRate()
    }

    getRenderData (context) {
      let left
      if (context == null) { context = {} }
      context = super.getRenderData(context)
      context.level = this.level
      context.authorized = me.isAdmin() || this.level.hasWriteAccess(me)
      context.anonymous = me.get('anonymous')
      context.recentlyPlayedOpponents = (left = __guard__(storage.load('recently-played-matches'), x => x[this.levelID])) != null ? left : []
      return context
    }

    afterRender () {
      super.afterRender()
      if (!this.supermodel.finished()) { return }
      if (!this.fullyRenderedOnce) {
        this.listenTo(this.level, 'change:tasks', () => this.renderSelectors('#tasks-tab'))
      }
      this.thangsTabView = this.insertSubView(new ThangsTabView({ world: this.world, supermodel: this.supermodel, level: this.level, previouslyLoadedData: this.previouslyLoadedSubviewData }))
      this.insertSubView(new SettingsTabView({ supermodel: this.supermodel, previouslyLoadedData: this.previouslyLoadedSubviewData }))
      this.insertSubView(new ScriptsTabView({ world: this.world, supermodel: this.supermodel, files: this.files }))
      this.insertSubView(new ComponentsTabView({ supermodel: this.supermodel }))
      this.insertSubView(new SystemsTabView({ supermodel: this.supermodel, world: this.world }))
      this.insertKeyThangTabViews()
      this.insertSubView(new TasksTabView({ world: this.world, supermodel: this.supermodel, level: this.level }))
      this.insertSubView(new RelatedAchievementsView({ supermodel: this.supermodel, level: this.level }))
      this.insertSubView(new ComponentsDocumentationView({ lazy: true })) // Don't give it the supermodel, it'll pollute it!
      this.insertSubView(new SystemsDocumentationView({ lazy: true })) // Don't give it the supermodel, it'll pollute it!
      this.insertSubView(new LevelFeedbackView({ level: this.level }))
      this.$el.find('a[data-toggle="tab"]').on('shown.bs.tab', e => {
        return Backbone.Mediator.publish('editor:view-switched', { targetURL: $(e.target).attr('href') })
      })

      Backbone.Mediator.publish('editor:level-loaded', { level: this.level })
      if (!this.fullyRenderedOnce && me.get('anonymous')) { this.showReadOnly() }
      this.patchesView = this.insertSubView(new PatchesView(this.level), this.$el.find('.patches-view'))
      this.listenTo(this.patchesView, 'accepted-patch', function (attrs) {
        if (attrs != null ? attrs.save : undefined) {
          const f = () => this.startCommittingLevel(attrs)
          return setTimeout(f, 400) // Give some time for closing patch modal
        } else {
          if (!key.shift) { return location.reload() }
        }
      }) // Reload to make sure changes propagate, unless secret shift shortcut
      if (this.level.watching()) { return this.$el.find('#level-watch-button').find('> span').toggleClass('secret') }
      this.fullyRenderedOnce = true
    }

    insertKeyThangTabViews () {
      if (this.keyThangTabViews == null) { this.keyThangTabViews = {} }
      this.keyThangIDs = ['Hero Placeholder', 'Hero Placeholder 1', 'Referee', 'RefereeJS', 'Level Manager', 'Level Manager JS'].reverse()
      for (const id of Array.from(this.keyThangIDs)) {
        var left, thang
        if (!(thang = _.find((left = this.level.get('thangs')) != null ? left : [], { id }))) { continue }
        if (this.keyThangTabViews[id]) { continue }
        const thangPath = this.thangsTabView.pathForThang(thang)
        const tabId = `key-thang-tab-view-${_.string.slugify(thang.id)}`
        const tabName = id.replace(/ ?(Placeholder|JS|Level)/g, '')
        const $subView = new KeyThangTabView({ thangData: thang, level: this.level, world: this.world, supermodel: this.supermodel, oldPath: thangPath, id: tabId })
        $subView.$el.insertAfter(this.$el.find('#systems-tab-view'))
        $subView.render()
        $subView.afterInsert()
        this.keyThangTabViews[id] = this.registerSubView($subView)
        const $tabBarEntry = $(`<li><a data-toggle='tab' href='#${tabId}'>${tabName}</a></li>`)
        $tabBarEntry.insertAfter(this.$el.find('a[href="#systems-tab-view"]').parent())
      }
      return null
    }

    onThangDeleted (e) {
      if (!Array.from(this.keyThangIDs != null ? this.keyThangIDs : []).includes(e.thangID)) { return }
      this.removeSubView(this.keyThangTabViews[e.thangID])
      this.keyThangTabViews[e.thangID] = null
    }

    openRevertModal (e) {
      e.stopPropagation()
      this.openModalView(new RevertModal())
    }

    openGenerateTerrainModal (e) {
      e.stopPropagation()
      this.openModalView(new GenerateTerrainModal())
    }

    onClickGenerateLevel (e) {
      e.stopPropagation()
      this.openModalView(new GenerateLevelModal())
    }

    onClickGeneratePracticeLevel (e) {
      this.generatePracticeLevel()
    }

    onClickGenerateAllPracticeLevels (e) {
      this.generatePracticeLevels()
    }

    onClickSaveAllPracticeLevels (e) {
      this.savePracticeLevels()
    }

    async generateLevel (e) {
      const parameters = {} // Temp: totally random parameters
      if (e?.size) {
        parameters.size = e.size
        this.lastLevelGenerationSize = e.size
      } else if (this.lastLevelGenerationSize) {
        parameters.size = this.lastLevelGenerationSize
      }
      levelGeneration.generateLevel({ parameters, supermodel: this.supermodel }).then(level => {
        if (this.destroyed) return
        console.log('generated level', level)
        this.setGeneratedLevel(level)
      })
    }

    async generatePracticeLevels (limit = 26) {
      const existingPracticeLevels = await fetchPracticeLevels(this.level.get('slug'))
      this.newPracticeLevels = []
      const generateUntil = Math.min(26, existingPracticeLevels.length + limit)
      this.level.revert()
      const originalThangs = _.cloneDeep(this.level.get('thangs'))
      console.log('Have existing practice levels', existingPracticeLevels)
      for (let levelIndex = existingPracticeLevels.length; levelIndex < generateUntil; ++levelIndex) {
        this.level.revert()
        const parameters = { sourceLevel: this.level, levelIndex, existingPracticeLevels, newPracticeLevels: this.newPracticeLevels, originalThangs, levelStats: this.levelStats }
        const level = await levelGeneration.generateLevel({ parameters, supermodel: this.supermodel })
        if (this.destroyed) return
        if (!level) break
        console.log('generated practice level', level)
        this.setGeneratedLevel(level)
        this.newPracticeLevels.push(level)
      }
      console.log('Have new practice levels', this.newPracticeLevels)
      this.$el.find('.save-all-practice-levels-button').toggleClass('hide', this.newPracticeLevels.length).text(`Save ${this.newPracticeLevels.length} New Practice Levels`)
    }

    async generatePracticeLevel () {
      await this.generatePracticeLevels(1)
    }

    setGeneratedLevel (level) {
      for (const key in level) {
        if (Level.schema.properties[key]) {
          this.level.set(key, level[key])
        }
      }

      this.previouslyLoadedSubviewData = {}
      for (const subview of Object.values(this.subviews)) {
        if (subview.getDataForReplacementView) {
          const subviewData = subview.getDataForReplacementView()
          this.previouslyLoadedSubviewData = { ...this.previouslyLoadedSubviewData, ...subviewData }
          if (subviewData.addThangsView) {
            // Don't destroy this one, we are going to reuse it
            delete subview.subviews.add_thangs_view
            subviewData.addThangsView.willDisappear()
          }
        }
        this.removeSubView(subview)
      }
      this.render()
      this.previouslyLoadedSubviewData.addThangsView?.didReappear()
    }

    async savePracticeLevels () {
      if (!this.newPracticeLevels.length) { return }

      // Fetch the main Achievement for the source level
      const relatedAchievements = await fetchJson(`/db/achievement?related=${this.level.get('original')}`) || []
      const sourceLevelAchievement = relatedAchievements[0]
      const sourceAchievementWorth = sourceLevelAchievement?.worth || 10
      const practiceAchievementWorth = Math.ceil(sourceAchievementWorth / 3)

      // Create and save the practice levels
      const savedPracticeLevels = []
      for (let i = 0; i < this.newPracticeLevels.length; i++) {
        const level = this.newPracticeLevels[i]
        const newLevel = new Level($.extend(true, {}, this.level.attributes))
        newLevel.unset('_id')
        newLevel.unset('version')
        newLevel.unset('creator')
        newLevel.unset('created')
        newLevel.unset('original')
        newLevel.unset('parent')
        newLevel.unset('i18n')
        newLevel.unset('i18nCoverage')
        newLevel.unset('tasks')
        newLevel.set('commitMessage', `Generated as practice from ${this.level.get('name')}`)
        newLevel.set('permissions', [{ access: 'owner', target: me.id }])
        for (const key in level) {
          if (Level.schema.properties[key]) {
            newLevel.set(key, level[key])
          }
        }
        try {
          await saveModel(newLevel, null, { type: 'POST' }) // Override PUT so we can trigger postFirstVersion logic
          savedPracticeLevels.push(newLevel)
          noty({ timeout: 2000, text: `Created ${newLevel.get('name')}`, type: 'info', layout: 'top' })
        } catch (error) {
          noty({ timeout: 8000, text: `Error creating ${newLevel.get('name')}: ${error.responseText || error.message}`, type: 'error', layout: 'top' })
        }
      }

      // Now create and save achievements for all practice levels
      for (let i = 0; i < savedPracticeLevels.length; i++) {
        const practiceLevel = savedPracticeLevels[i]
        const achievement = new Achievement({
          name: `${practiceLevel.get('name')} Complete`,
          description: '',
          query: {
            'state.complete': true,
            'level.original': practiceLevel.get('original')
          },
          collection: 'level.sessions',
          userField: 'creator',
          related: practiceLevel.get('original'),
          worth: practiceAchievementWorth,
          rewards: {
            gems: practiceAchievementWorth,
            levels: []
          },
        })

        // Set the next level to unlock, if it's not the last practice level
        if (i < savedPracticeLevels.length - 1) {
          achievement.get('rewards').levels.push(savedPracticeLevels[i + 1].get('original'))
        }

        try {
          await saveModel(achievement, null, { type: 'POST' })
          noty({ timeout: 2000, text: `Created achievement for ${practiceLevel.get('name')}`, type: 'info', layout: 'top' })
        } catch (error) {
          noty({ timeout: 8000, text: `Error creating achievement for ${practiceLevel.get('name')}: ${error.responseText || error.message}`, type: 'error', layout: 'top' })
        }
      }

      // Update main Achievement to unlock the first practice level
      if (savedPracticeLevels.length > 0) {
        const rewards = sourceLevelAchievement.rewards || { levels: [] }
        if (!rewards.levels.includes(savedPracticeLevels[0].get('original'))) {
          rewards.levels.push(savedPracticeLevels[0].get('original'))

          const sourceLevelAchievementModel = new Achievement({ _id: sourceLevelAchievement._id })
          sourceLevelAchievementModel.set(sourceLevelAchievement)
          sourceLevelAchievementModel.set('rewards', rewards)
          try {
            await saveModel(sourceLevelAchievementModel, null, { patch: true, type: 'PUT' })
            noty({ timeout: 2000, text: 'Updated main achievement to unlock first practice level', type: 'info', layout: 'top' })
          } catch (error) {
            noty({ timeout: 8000, text: `Error updating main achievement: ${error.responseText || error.message}`, type: 'error', layout: 'top' })
          }
        }
      }

      // TODO: update the main level with its practiceThresholdMinutes

      // Update the campaign with practice levels
      await this.updateCampaignWithPracticeLevels(savedPracticeLevels)
    }

    async updateCampaignWithPracticeLevels (practiceLevels) {
      try {
        const campaignId = '65c56663d2ca2055e65676af'
        const sourceLevelOriginal = this.level.get('original')
        const updatedCampaign = await this.insertPracticeLevelsIntoCampaign(campaignId, sourceLevelOriginal, practiceLevels)
        console.log('Updated campaign', updatedCampaign)
        noty({ timeout: 2000, text: 'Updated campaign with practice levels', type: 'success', layout: 'top' })
      } catch (error) {
        noty({ timeout: 8000, text: `Error updating campaign: ${error.message}`, type: 'error', layout: 'top' })
        console.error(error)
      }
    }

    async insertPracticeLevelsIntoCampaign (campaignId, sourceLevelOriginal, practiceLevels) {
      try {
        // Fetch the campaign
        const campaignAttrs = await fetchJson(`/db/campaign/${campaignId}`)
        if (!campaignAttrs) {
          throw new Error('Campaign not found')
        }

        const campaign = new Campaign({ _id: campaignId })
        campaign.set(campaignAttrs)

        // Put the new practice levels in it, after the source level
        const levels = campaign.get('levels') || {}
        const newLevels = {}
        let levelIndex = 0
        for (const [levelOriginal, levelData] of Object.entries(levels)) {
          newLevels[levelOriginal] = levelData
          if (levelOriginal === sourceLevelOriginal) {
            let practiceLevelIndex = 0
            for (const practiceLevel of practiceLevels) {
              const campaignPracticeLevel = _.pick(practiceLevel.attributes, Campaign.denormalizedLevelProperties)
              // Just put it on the bottom, we don't really use the position except in campagin editor
              // x, y, are % of width, height of the campaign map
              campaignPracticeLevel.position = { x: levelIndex / _.size(levels), y: practiceLevelIndex }
              newLevels[practiceLevel.get('original')] = campaignPracticeLevel
              ++practiceLevelIndex
            }
          }
          ++levelIndex
        }
        campaign.set('levels', newLevels)

        try {
          await saveModel(campaign, { levels: newLevels }, { patch: true, type: 'PUT' })
          noty({ timeout: 2000, text: 'Updated campaign to include new practice levels', type: 'info', layout: 'top' })
        } catch (error) {
          noty({ timeout: 8000, text: `Error updating campaign: ${error.responseText || error.message}`, type: 'error', layout: 'top' })
        }

        return campaign
      } catch (error) {
        console.error('Error inserting practice levels into campaign:', error)
        throw error
      }
    }

    onPlayLevelTeamSelect (e) {
      if (this.childWindow && !this.childWindow.closed) {
        // We already have a child window open, so we don't need to ask for a team; we'll use its existing team.
        e.stopImmediatePropagation()
        return this.onPlayLevel(e)
      }
    }

    onPlayLevel (e) {
      let left, newClassMode
      const team = $(e.target).data('team')
      const opponentSessionID = $(e.target).data('opponent')
      if ($(e.target).data('classroom') === 'home') {
        newClassMode = (this.lastNewClassMode = undefined)
      } else if ($(e.target).data('classroom')) {
        newClassMode = (this.lastNewClassMode = true)
      } else {
        newClassMode = this.lastNewClassMode
      }
      const newClassLanguage = (this.lastNewClassLanguage = ((left = $(e.target).data('code-language')) != null ? left : this.lastNewClassLanguage) || undefined)
      if (utils.isOzaria && this.childWindow && (this.childWindow.closed || !this.childWindow.onPlayLevelViewLoaded)) {
        __guardMethod__(this.childWindow, 'close', o => o.close())
        return noty({ timeout: 4000, text: 'Error: child window disconnected, you will have to reload this page to preview.', type: 'error', layout: 'top' })
      }
      const sendLevel = () => {
        return this.childWindow.Backbone.Mediator.publish('level:reload-from-data', { level: this.level, supermodel: this.supermodel })
      }
      if (this.childWindow && !this.childWindow.closed && (this.playClassMode === newClassMode) && (this.playClassLanguage === newClassLanguage)) {
        // Reset the LevelView's world, but leave the rest of the state alone
        sendLevel()
      } else {
        // Create a new Window with a blank LevelView
        let scratchLevelID = this.level.get('slug') + '?dev=true'
        if (team) { scratchLevelID += `&team=${team}` }
        if (opponentSessionID) { scratchLevelID += `&opponent=${opponentSessionID}` }
        this.playClassMode = newClassMode
        this.playClassLanguage = newClassLanguage
        if (this.playClassMode) {
          scratchLevelID += `&course=${this.courseID}`
          scratchLevelID += `&codeLanguage=${this.playClassLanguage}`
        }
        if (utils.isOzaria) {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window')
        } else if (me.get('name') === 'Nick') {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
        } else {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=1280,height=640,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
        }
        this.childWindow.onPlayLevelViewLoaded = e => sendLevel() // still a hack
      }
      return this.childWindow.focus()
    }

    onUndo () {
      return __guard__(TreemaNode.getLastTreemaWithFocus(), x => x.undo())
    }

    onRedo () {
      return __guard__(TreemaNode.getLastTreemaWithFocus(), x => x.redo())
    }

    showUndoDescription () {
      const undoDescription = TreemaNode.getLastTreemaWithFocus().getUndoDescription()
      return this.$el.find('#undo-button').attr('title', $.i18n.t('general.undo_prefix') + ' ' + undoDescription + ' ' + $.i18n.t('general.undo_shortcut'))
    }

    showRedoDescription () {
      const redoDescription = TreemaNode.getLastTreemaWithFocus().getRedoDescription()
      return this.$el.find('#redo-button').attr('title', $.i18n.t('general.redo_prefix') + ' ' + redoDescription + ' ' + $.i18n.t('general.redo_shortcut'))
    }

    getCurrentView () {
      let currentViewID = this.$el.find('.tab-pane.active').attr('id')
      if (currentViewID === 'editor-level-patches') { return this.patchesView }
      if (currentViewID === 'editor-level-documentation') { currentViewID = 'components-documentation-view' }
      return this.subviews[_.string.underscored(currentViewID)]
    }

    startPatchingLevel (e) {
      this.openModalView(new SaveVersionModal({ model: this.level }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    startCommittingLevel (e) {
      this.openModalView(new SaveLevelModal({ level: this.level, supermodel: this.supermodel, buildTime: this.levelBuildTime, commitMessage: (e != null ? e.commitMessage : undefined) }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    showArtisanGuide (e) {
      this.openModalView(new ArtisanGuideModal({ level: this.level }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    startForking (e) {
      this.openModalView(new ForkModal({ model: this.level, editorPath: 'level' }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    showVersionHistory (e) {
      const versionHistoryView = new VersionHistoryView({ level: this.level }, this.levelID)
      this.openModalView(versionHistoryView)
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    toggleWatchLevel () {
      const button = this.$el.find('#level-watch-button')
      this.level.watch(button.find('.watch').is(':visible'))
      return button.find('> span').toggleClass('secret')
    }

    onPopulateI18N () {
      let totalChanges = this.level.populateI18N()

      const levelComponentMap = _(globalVar.currentView.supermodel.getModels(LevelComponent))
        .map(c => [c.get('original'), c])
        .object()
        .value()

      const iterable = this.level.get('thangs')
      for (let thangIndex = 0; thangIndex < iterable.length; thangIndex++) {
        const thang = iterable[thangIndex]
        for (let thangComponentIndex = 0; thangComponentIndex < thang.components.length; thangComponentIndex++) {
          const thangComponent = thang.components[thangComponentIndex]
          const component = levelComponentMap[thangComponent.original]
          const configSchema = component.get('configSchema')
          const path = `/thangs/${thangIndex}/components/${thangComponentIndex}/config`
          totalChanges += this.level.populateI18N(thangComponent.config, configSchema, path)
        }
      }

      if (totalChanges) {
        const f = () => document.location.reload()
        return setTimeout(f, 500)
      } else {
        return noty({ timeout: 2000, text: 'No changes.', type: 'information', layout: 'topRight' })
      }
    }

    onClickSaveBranch () {
      const components = new LevelComponents(this.supermodel.getModels(LevelComponent))
      const systems = new LevelSystems(this.supermodel.getModels(LevelSystem))
      this.openModalView(new SaveBranchModal({ components, systems }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    onClickLoadBranch () {
      const components = new LevelComponents(this.supermodel.getModels(LevelComponent))
      const systems = new LevelSystems(this.supermodel.getModels(LevelSystem))
      this.openModalView(new LoadBranchModal({ components, systems }))
      return Backbone.Mediator.publish('editor:view-switched', {})
    }

    toggleTab (e) {
      this.renderScrollbar()
      if (!($(document).width() <= 800)) { return }
      const li = $(e.target).closest('li')
      if (li.hasClass('active')) {
        li.parent().find('li').show()
      } else {
        li.parent().find('li').hide()
        li.show()
      }
      return console.log(li.hasClass('active'))
    }

    onClickDocumentationTab (e) {
      // It's either too late at night or something is going on with Bootstrap nested tabs, so we do the click instead of using .active.
      if (this.initializedDocs) { return }
      this.initializedDocs = true
      return this.$el.find('a[href="#components-documentation-view"]').click()
    }

    onClickMigrateJunior (e) {
      Backbone.Mediator.publish('editor:migrate-junior', {})
    }

    incrementBuildTime () {
      if (application.userIsIdle) { return }
      if (this.levelBuildTime == null) {
        let left
        this.levelBuildTime = (left = this.level.get('buildTime')) != null ? left : 0
      }
      return ++this.levelBuildTime
    }

    checkPresence () {
      if (!this.level.get('original')) { return }
      return presenceApi.getPresence({ levelOriginalId: this.level.get('original') })
        .then(this.updatePresenceUI)
        .catch(this.updatePresenceUI)
    }

    updatePresenceUI (emails) {
      $('#dropdownPresenceMenu').empty()
      if (!Array.isArray(emails)) {
        $('#presence-number').text('?')
        return
      }
      if (emails == null) { emails = [] }
      $('#presence-number').text(emails.length || 0)
      return emails.forEach(email => $('#dropdownPresenceMenu').append(`<li>${email}</li>`))
    }

    getTaskCompletionRatio () {
      if ((this.level.get('tasks') == null)) {
        return '0/0'
      } else {
        return _.filter(this.level.get('tasks'), _elem => _elem.complete).length + '/' + this.level.get('tasks').length
      }
    }

    async getLevelCompletionRate () {
      if (!me.isAdmin()) { return }
      this.levelStats = await fetchLevelStats(this.level.get('original'))
      if (this.levelStats.completionRate == null || !this.levelStats.playtime?.p50) {
        return // No stats yet
      }
      const rateDisplay = (this.levelStats.completionRate * 100).toFixed(1) + '%'
      this.$('#completion-rate').text(rateDisplay).removeClass('hide')
      this.$('#completion-time').text(this.levelStats.playtime.p50 + 's').attr('title', JSON.stringify(this.levelStats.playtime)).removeClass('hide')
    }
  }
  LevelEditView.initClass()
  return LevelEditView
})())

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
function __guardMethod__ (obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName)
  } else {
    return undefined
  }
}

function saveModel (model, attributes, options = {}) {
  return new Promise((resolve, reject) => {
    model.save(attributes, {
      ...options,
      success: (model, response) => resolve(response),
      error: (model, response) => reject(response)
    })
  })
}
