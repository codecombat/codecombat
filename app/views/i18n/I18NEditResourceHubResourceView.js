import I18NEditModelView from './I18NEditModelView';
import ResourceHubResource from 'models/ResourceHubResource';

class I18NEditResourceHubResource extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      const link = this.model.get('link')
      const description = this.model.get('description')
      if (name) {
        this.wrapRow('Label / Name', ['name'], name, i18n[lang]?.name, [])
      }

      if (link) {
        this.wrapRow('Link to resource', ['link'], link, i18n[lang]?.link, [])
      }

      if (description) {
        this.wrapRow('Resource description', ['description'], description, i18n[lang]?.description, [], 'markdown')
      }
    }
  }
}

I18NEditResourceHubResource.prototype.id = 'i18n-edit-resource_hub_resource-view'
I18NEditResourceHubResource.prototype.modelClass = ResourceHubResource

export default I18NEditResourceHubResource;
