const NewModelModal = require('views/editor/modal/NewModelModal')
const template = require('app/templates/editor/ai-model/modal/new-ai-model')
// const forms = require('core/forms')
const AIModel = require('models/AIModel')

class NewAIModelModal extends NewModelModal {
  id = 'new-ai-model-modal'
  template = template
  plain = false
  events = { 'click #save-new-ai-model-link': 'onAIModelSubmitted' }


  onAIModelSubmitted(e) {
    const slug = _.string.slugify(this.$el.find('#name').val())
    const url = `/editor/ai-model/${slug}`
    return window.open(url, '_blank')
  }

  makeNewModel() {
    console.log('here')
    const aiModel = new AIModel()
    const name = this.$el.find('#name').val()
    const family = this.$el.find('#family').val()

    aiModel.set('name', name)
    aiModel.set('family', family)

    return aiModel
  }
}

module.exports = NewAIModelModal
