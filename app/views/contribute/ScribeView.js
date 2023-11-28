// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ScribeView
const ContributeClassView = require('./ContributeClassView')
const template = require('app/templates/contribute/scribe')
const { me } = require('core/auth')
const ContactModal = require('views/core/ContactModal')

module.exports = (ScribeView = (function () {
  ScribeView = class ScribeView extends ContributeClassView {
    static initClass () {
      this.prototype.id = 'scribe-view'
      this.prototype.template = template

      this.prototype.events =
        { 'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal' }

      this.prototype.contributors = [
        { name: 'Ryan Faidley' },
        { name: 'Mischa Lewis-Norelle', github: 'mlewisno' },
        { name: 'Tavio' },
        { name: 'Ronnie Cheng', github: 'rhc2104' },
        { name: 'engstrom' },
        { name: 'Dman19993' },
        { name: 'mattinsler' }
      ]
    }

    initialize () {
      return this.contributorClassName = 'scribe'
    }

    openContactModal (e) {
      e.stopPropagation()
      return this.openModalView(new ContactModal())
    }
  }
  ScribeView.initClass()
  return ScribeView
})())
