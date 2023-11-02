const CocoModel = require('./CocoModel')
const schema = require('schemas/models/level_component')
const _ = require('lodash')

class LevelComponent extends CocoModel {
  constructor () {
    super()
  }

  set (key, val, options) {
    let attrs
    if (_.isObject(key)) {
      [attrs, options] = [key, val]
    } else {
      attrs = {}
      attrs[key] = val
    }
    if ('code' in attrs && !('js' in attrs)) {
      attrs.js = this.compile(attrs.code)
    }
    return super.set(attrs, options)
  }

  onLoaded () {
    super.onLoaded()
    if (!this.get('js')) {
      return this.set('js', this.compile(this.get('code')))
    }
  }

  compile (code) {
    let js
    if (this.get('codeLanguage') && this.get('codeLanguage') === 'javascript') {
      return code
    }
    if (this.get('codeLanguage') && this.get('codeLanguage') !== 'coffeescript') {
      console.error('Can\'t compile', this.get('codeLanguage'), '-- only CoffeeScript/JavaScript.', this)
      return
    }
    try {
      js = CoffeeScript.compile(code, { bare: true })
    } catch (e) {
      js = this.get('js')
    }
    return js
  }

  getDependencies (allComponents) {
    const results = []
    for (const dep of (this.get('dependencies') || [])) {
      const comp = _.find(allComponents, c => (c.get('original') === dep.original) && (c.get('version').major === dep.majorVersion))
      for (const result of comp.getDependencies(allComponents).concat([comp])) {
        if (!results.includes(result)) {
          results.push(result)
        }
      }
    }
    return results
  }
}

LevelComponent.className = 'LevelComponent'
LevelComponent.schema = schema
LevelComponent.prototype.urlRoot = '/db/level.component'
LevelComponent.prototype.editableByArtisans = true

LevelComponent.EquipsID = '53e217d253457600003e3ebb'
LevelComponent.ItemID = '53e12043b82921000051cdf9'
LevelComponent.AttacksID = '524b7ba57fc0f6d519000016'
LevelComponent.PhysicalID = '524b75ad7fc0f6d519000001'
LevelComponent.ExistsID = '524b4150ff92f1f4f8000024'
LevelComponent.LandID = '524b7aff7fc0f6d519000006'
LevelComponent.CollidesID = '524b7b857fc0f6d519000012'
LevelComponent.PlansID = '524b7b517fc0f6d51900000d'
LevelComponent.ProgrammableID = '524b7b5a7fc0f6d51900000e'
LevelComponent.MovesID = '524b7b8c7fc0f6d519000013'
LevelComponent.MissileID = '524cc2593ea855e0ab000142'
LevelComponent.FindsPathsID = '52872b0ead92b98561000002'
LevelComponent.AttackableID = '524b7bab7fc0f6d519000017'
LevelComponent.RefereeID = '54977ce657e90bd1903dea72'

LevelComponent.ProgrammableIDs = [
  '524b7b5a7fc0f6d51900000e',
  '5f7d7be6bad19a002837b394'
]

LevelComponent.positionIDs = [
  '524b75ad7fc0f6d519000001',
  '5f589b061d240e002298f852'
]
LevelComponent.shapeIDs = [
  '524b75ad7fc0f6d519000001',
  '5f58cbfe3f40380023b02f3c'
]
LevelComponent.collisionIDs = [
  '524b7b857fc0f6d519000012',
  '5f5a19ba36dd000023f89f7b'
]

module.exports = LevelComponent
