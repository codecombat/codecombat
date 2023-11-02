// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/level_system')
const SystemNameLoader = require('core/SystemNameLoader')
const _ = require('lodash')

class LevelSystem extends CocoModel {
  constructor () {
    super()
    this.className = 'LevelSystem'
    this.schema = schema
    this.urlRoot = '/db/level.system'
    this.editableByArtisans = true
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
      this.set('js', this.compile(this.get('code')))
    }
    SystemNameLoader.setName(this)
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
      // console.log 'couldn\'t compile', code, 'for', @get('name'), 'because', e
      js = this.get('js')
    }
    return js
  }

  getDependencies (allSystems) {
    const results = []
    for (const dep of Array.from(this.get('dependencies') || [])) {
      const system = _.find(allSystems, sys => (sys.get('original') === dep.original) && (sys.get('version').major === dep.majorVersion))
      for (const result of Array.from(system.getDependencies(allSystems).concat([system]))) {
        if (!Array.from(results).includes(result)) { results.push(result) }
      }
    }
    return results
  }
}

module.exports = LevelSystem
