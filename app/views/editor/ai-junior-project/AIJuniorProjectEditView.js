// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIJuniorProjectEditView
require('app/styles/editor/ai-junior-project/edit.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/ai-junior-project/edit')
const AIJuniorProject = require('models/AIJuniorProject')
const ConfirmModal = require('views/core/ConfirmModal')

const nodes = require('views/editor/level/treema_nodes')

require('lib/game-libraries')
require('lib/setupTreema')
require('core/treema-ext')

module.exports = (AIJuniorProjectEditView = (function () {
  AIJuniorProjectEditView = class AIJuniorProjectEditView extends RootView {
    static initClass () {
      this.prototype.id = 'editor-ai-junior-project-edit-view'
      this.prototype.template = template

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #delete-button': 'confirmDeletion'
      }
    }

    constructor (options, projectID) {
      super(options)
      this.deleteAIJuniorProject = this.deleteAIJuniorProject.bind(this)
      this.projectID = projectID
      this.project = new AIJuniorProject({ _id: this.projectID })
      this.project.saveBackups = true
      this.supermodel.loadModel(this.project)
    }

    onLoaded () {
      super.onLoaded()
      this.buildTreema()
      this.listenTo(this.project, 'change', () => {
        this.treema.set('/', this.project.attributes)
      })
    }

    buildTreema () {
      if ((this.treema != null) || (!this.project.loaded)) { return }
      const data = $.extend(true, {}, this.project.attributes)
      const options = {
        data,
        filePath: `db/ai_junior_project/${this.project.get('_id')}`,
        schema: AIJuniorProject.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode
        }
      }
      this.treema = this.$el.find('#ai-junior-project-treema').treema(options)
      this.treema.build()
      this.treema.open(2)
    }

    onClickSaveButton (e) {
      this.treema.endExistingEdits()
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.project.set(key, value)
      }

      const res = this.project.save()

      res.error((collection, response, options) => {
        console.error(response)
      })

      res.success(() => {
        const url = `/editor/ai-junior-project/${this.project.get('slug') || this.project.id}`
        document.location.href = url
      })
    }

    confirmDeletion () {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the project.',
        decline: 'Not really',
        confirm: 'Definitely'
      }

      const confirmModal = new ConfirmModal(renderData)
      confirmModal.on('confirm', this.deleteAIJuniorProject)
      this.openModalView(confirmModal)
    }

    deleteAIJuniorProject () {
      $.ajax({
        type: 'DELETE',
        success () {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          })
          _.delay(() => application.router.navigate('/editor/ai-junior-project', { trigger: true })
            , 500)
        },
        error (jqXHR, status, error) {
          console.error(jqXHR)
          noty({
            timeout: 5000,
            text: `Deleting project message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          })
        },
        url: `/db/ai_junior_project/${this.project.id}`
      })
    }
  }
  AIJuniorProjectEditView.initClass()
  return AIJuniorProjectEditView
})())
