import I18NEditModelView from './I18NEditModelView';
import Cutscene from 'ozaria/site/models/Cutscene';

class I18NEditCutsceneView extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      const displayName = this.model.get('displayName')
      if (name) {
        this.wrapRow('Short Name / Internal Name', ['name'], name, (i18n[lang] || {}).name, [])
      }
      if (displayName) {
        this.wrapRow('Display Name', ['displayName'], displayName, (i18n[lang] || {}).displayName, [])
      }
    }
  }
}

I18NEditCutsceneView.prototype.id = 'i18n-edit-cutscene-view'
I18NEditCutsceneView.prototype.modelClass = Cutscene

export default I18NEditCutsceneView;
