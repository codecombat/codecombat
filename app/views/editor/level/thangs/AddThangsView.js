// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AddThangsView
require('app/styles/editor/level/add-thangs-view.sass')
const CocoView = require('views/core/CocoView')
const addThangsTemplate = require('app/templates/editor/level/add-thangs-view')
const ThangType = require('models/ThangType')
const CocoCollection = require('collections/CocoCollection')
const utils = require('core/utils')

const PAGE_SIZE = 1000

class ThangTypeSearchCollection extends CocoCollection {
  static initClass () {
    this.prototype.url = '/db/thang.type?project=original,name,version,description,slug,kind,rasterIcon'
    this.prototype.model = ThangType
  }
}
ThangTypeSearchCollection.initClass()

module.exports = (AddThangsView = (function () {
  AddThangsView = class AddThangsView extends CocoView {
    static initClass () {
      this.prototype.id = 'add-thangs-view'
      this.prototype.className = 'add-thangs-palette'
      this.prototype.template = addThangsTemplate

      this.prototype.events =
        { 'keyup input#thang-search': 'runSearch' }
    }

    constructor (options) {
      super(options)
      this.runSearch = this.runSearch.bind(this)
      this.world = options.world

      this.thangTypes = new Backbone.Collection()
      const thangTypeCollection = new ThangTypeSearchCollection([])
      if (utils.isOzaria) {
        thangTypeCollection.url += '&archived=false'
      }
      thangTypeCollection.fetch({ data: { limit: PAGE_SIZE } })
      thangTypeCollection.skip = 0
      // should load depended-on Components, too
      this.supermodel.loadCollection(thangTypeCollection, 'thangs')
      this.listenTo(thangTypeCollection, 'sync', this.onThangCollectionSynced)
    }

    onThangCollectionSynced (collection) {
      const getMore = collection.models.length === PAGE_SIZE
      this.thangTypes.add(collection.models)
      this.render()
      if (getMore) {
        collection.skip += PAGE_SIZE
        collection.fetch({ data: { skip: collection.skip, limit: PAGE_SIZE } })
        return this.supermodel.loadCollection(collection, 'thangs')
      }
    }

    getRenderData (context) {
      let models
      context = context || {}
      context = super.getRenderData(context)
      if (this.searchModels) {
        models = this.searchModels
      } else {
        models = this.supermodel.getModels(ThangType)
      }

      let thangTypes = _.uniq(models, false, thangType => thangType.get('original'))
      thangTypes = _.reject(thangTypes, thangType => ['Mark', 'Item', undefined].includes(thangType.get('kind')))
      const groupMap = {}
      for (const thangType of thangTypes) {
        const kind = thangType.get('kind')
        groupMap[kind] = groupMap[kind] || []
        groupMap[kind].push(thangType)
      }

      let groups = []
      for (const groupName of Object.keys(groupMap).sort()) {
        let someThangTypes = groupMap[groupName]
        someThangTypes = _.sortBy(someThangTypes, thangType => thangType.get('name'))
        const group = {
          name: groupName,
          thangs: someThangTypes
        }
        groups.push(group)
      }

      groups = _.sortBy(groups, function (group) {
        const index = ['Wall', 'Junior', 'Floor', 'Unit', 'Doodad', 'Misc'].indexOf(group.name)
        if (index === -1) { return 9001 } else { return index }
      })

      context.thangTypes = thangTypes
      context.groups = groups
      return context
    }

    afterRender () {
      super.afterRender()
      this.buildAddThangPopovers()
    }

    buildAddThangPopovers () {
      this.$el.find('#thangs-list .add-thang-palette-icon').addClass('has-tooltip').tooltip({ container: 'body', animation: false })
    }

    runSearch (e) {
      if (e?.which === 27) {
        this.onEscapePressed()
      }
      const term = this.$el.find('input#thang-search').val()
      if (term === this.lastSearch) { return }

      this.searchModels = this.thangTypes.filter(function (model) {
        if (!term) { return true }
        const regExp = new RegExp(term, 'i')
        return model.get('name').match(regExp)
      })
      this.render()
      this.$el.find('input#thang-search').focus().val(term)
      this.lastSearch = term
    }

    onEscapePressed () {
      this.$el.find('input#thang-search').val('')
      this.runSearch()
    }
  }
  AddThangsView.initClass()
  return AddThangsView
})())
