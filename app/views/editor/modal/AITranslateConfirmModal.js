let AITranslateConfirmModal
const ModalComponent = require('views/core/ModalComponent')
const AITranslateConfirmComponent = require('./AITranslateConfirmView.vue').default
const { aiTranslate } = require('core/utils')

const relatedModels = ['AIScenario', 'Level']

async function sendRequestsWithLimit (requests, limit = 10) {
  const results = []
  const executing = []
  for (const request of requests) {
    const promise = request().then(result => {
      executing.splice(executing.indexOf(promise), 1)
      return result
    })

    results.push(promise)
    executing.push(promise)

    if (executing.length >= limit) {
      await Promise.race(executing)
    }
  }

  return Promise.all(results)
}

async function handleLevelRelatedModels (doc, langs) {
  const thangs = doc.get('thangs')
  const requests = []
  const uniqComponents = new Set()
  for (const thang of thangs) {
    const components = thang.components || []
    for (const component of components) {
      uniqComponents.add(component.original)
    }
  }
  // about 50 originals for each level
  for (const original of Array.from(uniqComponents)) {
    requests.push(() => aiTranslate('LevelComponent', original, langs))
  }
  await sendRequestsWithLimit(requests, 10)
}

async function handleAIScenarioRelatedModels (doc, langs) {
  const chatMessageIds = doc.get('initialActionQueue')
  for (const cId of chatMessageIds) {
    await aiTranslate('AIChatMessage', cId, langs)
  }
}

async function handleRealtedModels (doc, langs) {
  const className = doc.constructor.className
  if (!relatedModels.includes(className)) {
    return
  }
  if (className === 'AIScenario') {
    return await handleAIScenarioRelatedModels(doc, langs)
  } else if (className === 'Level') {
    return await handleLevelRelatedModels(doc, langs)
  }
}

module.exports = (AITranslateConfirmModal = (function () {
  AITranslateConfirmModal = class AITranslateConfirmModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'AITranslateConfirm-modal'
      this.prototype.template = require('app/templates/core/modal-base-flat')
      this.prototype.VueComponent = AITranslateConfirmComponent
    }

    constructor (doc, options) {
      super(options)

      this.doc = doc
      this.langs = []
      this.propsData = {
        hide: () => this.hide(),
      }
    }

    afterRender () {
      super.afterRender()
      this.vueComponent.$on('update-langs', (data) => {
        this.langs = data
      })

      this.vueComponent.$on('confirm-translate', async () => {
        await handleRealtedModels(this.doc, this.langs)
        await aiTranslate(this.doc.constructor.className, this.doc.id, this.langs)
        window.location.reload()
      })
    }

    destroy () {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy()
      }
      return super.destroy()
    }
  }
  AITranslateConfirmModal.initClass()
  return AITranslateConfirmModal
})())
