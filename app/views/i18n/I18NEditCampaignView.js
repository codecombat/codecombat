// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditCampaignView
const I18NEditModelView = require('./I18NEditModelView')
const Campaign = require('models/Campaign')

module.exports = (I18NEditCampaignView = (function () {
  I18NEditCampaignView = class I18NEditCampaignView extends I18NEditModelView {
    static initClass () {
      this.prototype.id = 'i18n-edit-campaign-view'
      this.prototype.modelClass = Campaign
    }

    buildTranslationList () {
      let i18n
      const lang = this.selectedLanguage

      // name, description
      if (i18n = this.model.get('i18n')) {
        let description, fullName, name
        if (name = this.model.get('name')) {
          this.wrapRow('Campaign short name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, [])
        }
        if (fullName = this.model.get('fullName')) {
          this.wrapRow('Campaign full name', ['fullName'], fullName, i18n[lang] != null ? i18n[lang].fullName : undefined, [])
        }
        if (description = this.model.get('description')) {
          return this.wrapRow('Campaign description', ['description'], description, i18n[lang] != null ? i18n[lang].description : undefined, [])
        }
      }
    }
  }
  I18NEditCampaignView.initClass()
  return I18NEditCampaignView
})())
