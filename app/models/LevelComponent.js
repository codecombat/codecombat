// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelComponent
const CocoModel = require('./CocoModel')

module.exports = (LevelComponent = (function () {
  LevelComponent = class LevelComponent extends CocoModel {
    static initClass () {
      this.className = 'LevelComponent'
      this.schema = require('schemas/models/level_component')

      this.EquipsID = '53e217d253457600003e3ebb'
      this.ItemID = '53e12043b82921000051cdf9'
      this.AttacksID = '524b7ba57fc0f6d519000016'
      this.PhysicalID = '524b75ad7fc0f6d519000001'
      this.ExistsID = '524b4150ff92f1f4f8000024'
      this.LandID = '524b7aff7fc0f6d519000006'
      this.CollidesID = '524b7b857fc0f6d519000012'
      this.PlansID = '524b7b517fc0f6d51900000d'
      this.ProgrammableID = '524b7b5a7fc0f6d51900000e'
      this.MovesID = '524b7b8c7fc0f6d519000013'
      this.MissileID = '524cc2593ea855e0ab000142'
      this.FindsPathsID = '52872b0ead92b98561000002'
      this.AttackableID = '524b7bab7fc0f6d519000017'
      this.RefereeID = '54977ce657e90bd1903dea72'
      this.JuniorPlayerID = '65b29e528f43392e778c9433'

      this.ProgrammableIDs = [
        '524b7b5a7fc0f6d51900000e',
        '5f7d7be6bad19a002837b394'
      ]

      this.positionIDs = [
        '524b75ad7fc0f6d519000001',
        '5f589b061d240e002298f852'
      ]
      this.shapeIDs = [
        '524b75ad7fc0f6d519000001',
        '5f58cbfe3f40380023b02f3c'
      ]
      this.collisionIDs = [
        '524b7b857fc0f6d519000012',
        '5f5a19ba36dd000023f89f7b'
      ]

      this.prototype.urlRoot = '/db/level.component'
      this.prototype.editableByArtisans = true
    }

    set (key, val, options) {
      let attrs
      if (_.isObject(key)) {
        [attrs, options] = Array.from([key, val])
      } else {
        (attrs = {})[key] = val
      }
      if ('code' in attrs && !('js' in attrs)) {
        attrs.js = this.compile(attrs.code)
      }
      return super.set(attrs, options)
    }

    onLoaded () {
      super.onLoaded()
      if (!this.get('js')) { return this.set('js', this.compile(this.get('code'))) }
    }

    compile (code) {
      let js
      if (this.get('codeLanguage') && (this.get('codeLanguage') === 'javascript')) { return code }
      if (this.get('codeLanguage') && (this.get('codeLanguage') !== 'coffeescript')) {
        return console.error('Can\'t compile', this.get('codeLanguage'), '-- only CoffeeScript/JavaScript.', this)
      }
      try {
        js = CoffeeScript.compile(code, { bare: true })
      } catch (e) {
        console.log('couldn\'t compile', code, 'for', this.get('name'), 'because', e)
        js = this.get('js')
      }
      return js
    }

    getDependencies (allComponents) {
      const results = []
      for (const dep of Array.from(this.get('dependencies') || [])) {
        const comp = _.find(allComponents, c => (c.get('original') === dep.original) && (c.get('version').major === dep.majorVersion))
        for (const result of Array.from(comp.getDependencies(allComponents).concat([comp]))) {
          if (!Array.from(results).includes(result)) { results.push(result) }
        }
      }
      return results
    }
  }
  LevelComponent.initClass()
  return LevelComponent
})())
