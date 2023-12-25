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
let ItemDetailsView
require('app/styles/play/modal/item-details-view.sass')
const CocoView = require('views/core/CocoView')
const template = require('app/templates/play/modal/item-details-view')
const CocoCollection = require('collections/CocoCollection')
const LevelComponent = require('models/LevelComponent')

const utils = require('core/utils')

module.exports = (ItemDetailsView = (function () {
  ItemDetailsView = class ItemDetailsView extends CocoView {
    static initClass () {
      this.prototype.id = 'item-details-view'
      this.prototype.template = template
    }

    constructor () {
      super(...arguments)
      this.propDocs = {}
      this.spellDocs = {}
    }

    setItem (item) {
      let c
      this.item = item
      if (this.item) {
        this.spellDocs = {}
        this.item.name = utils.i18n(this.item.attributes, 'name')
        this.item.description = utils.i18n(this.item.attributes, 'description')
        this.item.affordable = me.gems() >= this.item.get('gems')
        this.item.owned = me.ownsItem(this.item.get('original'))
        this.item.comingSoon = !this.item.getFrontFacingStats().props.length && !_.size(this.item.getFrontFacingStats().stats) // Temp: while there are placeholder items
        this.componentConfigs = ((() => {
          const result = []
          for (c of Array.from(this.item.get('components'))) {
            if (c.config) {
              result.push(c.config)
            }
          }
          return result
        })())

        const stats = this.item.getFrontFacingStats()
        const props = (Array.from(stats.props).filter((p) => !this.propDocs[p]))
        if ((props.length > 0) || (Array.from(stats.props).includes('cast'))) {
          const docs = new CocoCollection([], {
            url: '/db/level.component?view=prop-doc-lookup',
            model: LevelComponent,
            project: [
              'name',
              'propertyDocumentation.name',
              'propertyDocumentation.description',
              'propertyDocumentation.i18n'
            ]
          })

          docs.fetch({
            data: {
              componentOriginals: [(() => {
                const result1 = []
                for (c of Array.from(this.item.get('components'))) {
                  result1.push(c.original)
                }
                return result1
              })()].join(','),
              propertyNames: props.join(',')
            }
          })
          this.listenToOnce(docs, 'sync', this.onDocsLoaded)
        }
      }

      return this.render()
    }

    onDocsLoaded (levelComponents) {
      for (const component of Array.from(levelComponents.models)) {
        for (const propDoc of Array.from(component.get('propertyDocumentation'))) {
          if (/^cast.+/.test(propDoc.name)) {
            this.spellDocs[propDoc.name] = propDoc
          } else {
            this.propDocs[propDoc.name] = propDoc
          }
        }
      }
      return this.render()
    }

    afterRender () {
      super.afterRender()
      return this.$el.find('.nano:visible').nanoScroller({ alwaysVisible: true })
    }

    getRenderData () {
      const c = super.getRenderData()
      c.item = this.item
      if (this.item) {
        let left
        const stats = this.item.getFrontFacingStats()
        c.stats = _.values(stats.stats)
        if (c.stats.length) { _.last(c.stats).isLast = true }
        c.props = []
        stats.props = _.union(stats.props, _.keys(this.spellDocs))
        const codeLanguage = ((left = me.get('aceConfig')) != null ? left : {}).language || 'python'
        for (const prop of Array.from(stats.props)) {
          let left1
          const doc = (left1 = this.propDocs[prop] != null ? this.propDocs[prop] : this.spellDocs[prop]) != null ? left1 : {}
          let description = utils.i18n(doc, 'description')

          if (_.isObject(description)) {
            description = description[codeLanguage] || _.values(description)[0]
          }
          if (_.isString(description)) {
            const fact = stats.stats.shieldDefenseFactor
            description = description.replace(/#{spriteName}/g, 'hero')
            if (fact) {
              description = description.replace(/#{shieldDefensePercent}%/g, fact.display)
            }
            if (prop === 'buildTypes') {
              const buildsConfig = _.find(this.componentConfigs, 'buildables')
              description = description.replace('#{buildTypes}', `\`[\"${_.keys(buildsConfig.buildables).join('\", \"')}\"]\``) // eslint-disable-line no-useless-escape
            }
            // We don't have the full components loaded here, so we can't really get most of these values.
            const componentConfigs = this.componentConfigs != null ? this.componentConfigs : []
            description = description.replace(/#{([^.]+?)}/g, function (match, keyChain) {
              for (const componentConfig of Array.from(componentConfigs)) {
                const value = utils.downTheChain(componentConfig, keyChain)
                if (value) {
                  return value
                }
              }
              // console.log 'gotta find', keyChain, 'from', match
              return match
            })
            description = description.replace(/#{(.+?)}/g, '`$1`')
            description = $(marked(description)).html()
          }

          c.props.push({
            name: prop,
            description: description || '...'
          })
        }
      }
      return c
    }
  }
  ItemDetailsView.initClass()
  return ItemDetailsView
})())
