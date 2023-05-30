import I18NEditModelView from './I18NEditModelView';
import Cinematic from 'ozaria/site/models/Cinematic';

class I18NEditCinematicView extends I18NEditModelView {
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
    const shots = this.model.get('shots') || []
    for (let shotIndex = 0; shotIndex < shots.length; shotIndex++) {
      const dialogNodes = shots[shotIndex].dialogNodes || []
      for (let dialogIndex = 0; dialogIndex < dialogNodes.length; dialogIndex++) {
        const dialogNode = dialogNodes[dialogIndex]
        const i18n = dialogNode.i18n
        if (i18n) {
          this.wrapRow(
            'Dialogue',
            ['text'],
            dialogNode.text,
            (i18n[lang] || {}).text,
            ['shots', shotIndex, 'dialogNodes', dialogIndex])
        }
      }
    }
  }
}

I18NEditCinematicView.prototype.id = 'i18n-edit-cinematic-view'
I18NEditCinematicView.prototype.modelClass = Cinematic

export default I18NEditCinematicView;
