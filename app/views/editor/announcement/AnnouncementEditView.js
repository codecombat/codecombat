const EditView = require('views/common/EditView')
const CocoCollection = require('collections/CocoCollection')
const Announcement = require('models/Announcement')
const AnnouncementSchema = require('schemas/models/announcement.schema')
const moment = require('moment')
const treemaExt = require('core/treema-ext')

class AnnouncementEditView extends EditView {
  resource = null
  schema = AnnouncementSchema
  redirectPathOnSuccess = '/editor/announcement'
  filePath = 'announcement'
  resourceName = 'Announcement'

  constructor (options = {}, resourceId) {
    super({})
    this.resource = new Announcement({ _id: resourceId })

    if (!this.resource.get('startDate')) {
      this.resource.set('startDate', new Date().toISOString())
    }
    if (!this.resource.get('endDate')) {
      this.resource.set('endDate', moment(this.resource.get('startDate')).add(1, 'months').toISOString())
    }
    if (!this.resource.get('query')) {
      this.resource.set('query', { _id: { $in: [me.get('_id').toString()] } })
    }
    this.supermodel.loadModel(this.resource)

    this.treemaOptions = {
      nodeClasses: {
        announcement: AnnouncementNode,
        markdown: ForceImageMarkUp,
        'mongo-query-user': QueryNode
      }

    }
  }
}

class ForceImageMarkUp extends treemaExt.LiveEditingMarkup {
  onFileUploaded (e) {
    const baseURL = `${document.location.protocol}//${document.location.host}`
    this.editor.insert(`![${e.metadata.name}](${baseURL}/file/${this.uploadingPath})`)
  }
}

class AnnouncementNode extends treemaExt.IDReferenceNode {
  valueClass = 'treema-announcement'
  lastTerm = null
  announcements = {}
  keyed = false
  ordered = false
  collection = false
  directlyEditable = true

  constructor (...args) {
    super(...args)
    // seems term search for announcement doesn't work well. so
    // here i search for all and filter it locally first.
    // TODO: fix the term search
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection([], { model: Announcement })
    this.collections.url = '/db/announcements?project[]=_id&project[]=name'
    this.collections.fetch()
    this.collections.once('sync', this.loadAnnouncements, this)
  }

  loadAnnouncements () {
    this.announcements = this.collections
    this.searchCallback()
  }

  buildValueForEditing (valEl, data) {
    valEl.html(this.searchValueTemplate)
    const input = valEl.find('input')
    input.focus().keyup(this.search)
    if (data) {
      input.attr('placeholder', this.formatDocument(data))
    }
  }

  searchCallback () {
    const container = this.getSearchResultsEl().detach().empty()
    let first = true
    this.collections.models.forEach(model => {
      const row = $('<div></div>').addClass('treema-search-result-row')
      const text = this.formatDocument(model)
      if (!text) {
        return
      }
      if (first) {
        row.addClass('treema-search-selected')
      }
      first = false
      row.text(text)
      row.data('value', model)
      container.append(row)
    })
    if (!this.collections.models.length) {
      container.append($('<div>No results</div>'))
    }
    this.getValEl().append(container)
  }

  search () {
    const term = this.getValEl().find('input').val()
    if (term === this.lastTerm) {
      return
    }
    this.lastTerm = term
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection(this.announcements.filter((ann) => {
      return ann.get('name').toLowerCase().includes(term.toLowerCase())
    }), { model: Announcement })
    this.searchCallback()
  }
}

class QueryNode extends window.TreemaObjectNode {
  valueClass = 'treema-mongo-query'
  childPropertiesAvailable () {
    return this.childSource
  }

  childSource (req, res) {
    const templates = [
      { label: 'Public', value: {} },
      { label: 'Registered Users', value: { anonymous: false } },
      { label: 'Teachers', value: { role: { $in: ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent'] } } },
      { label: 'Students', value: { role: 'student' } },
      { label: 'Home Users', value: { role: { $exists: false } } }
    ]

    const filtered = templates.filter((t) => {
      return t.label.toLowerCase().includes(req.term.toLowerCase())
    })
    res(filtered)
  }

  onAutocompleteSelect (e, ui) {
    this.addObjectNode(ui.item.value)
  }

  addObjectNode (data) {
    const newNode = window.TreemaNode.make(null, { schema: AnnouncementSchema.definitions.mongoFindQuery, data }, this.parent)
    this.replaceNode(newNode)
  }
}

module.exports = AnnouncementEditView
