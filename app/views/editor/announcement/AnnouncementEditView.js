const EditView = require('views/common/EditView')
const CocoCollection = require('collections/CocoCollection')
const Announcement = require('models/Announcement')
const AnnouncementSchema = require('schemas/models/announcement.schema')
const moment = require('moment')
const treemaExt = require('core/treema-ext')


class AnnouncementEditView extends EditView{
  resource = null
  schema = AnnouncementSchema
  redirectPathOnSuccess = '/editor/announcement'
  filePath = 'announcement'
  resourceName = 'Announcement'

  constructor(options = {}, resourceId) {
    super({})
    this.resource = new Announcement({ _id: resourceId })

    if (!this.resource.get('startDate')) {
      this.resource.set('startDate', new Date().toISOString())
    }
    if (!this.resource.get('endDate')) {
      this.resource.set('endDate', moment(this.resource.get('startDate')).add(1, 'months').toISOString())
    }
    this.supermodel.loadModel(this.resource)

    this.treemaOptions = {
      nodeClasses: {
        announcement: AnnouncementNode,
        'mongo-query-user': QueryNode
      }

    }
  }
}

class AnnouncementNode extends treemaExt.IDReferenceNode {
  valueClass = 'treema-announcement'
  lastTerm = 'x-x'
  announcements = {}

  constructor (...args) {
    super(...args)
    // seems term search for announcement doesn't work well. so
    // here i search for all and filter it locally first.
    // TODO: fix the term search
    this.getSearchResultsEl().empty().append('Searching')
    this.collection = new CocoCollection([], { model: Announcement })
    this.collection.url = '/db/announcements?project[]=_id&project[]=name'
    this.collection.fetch()
    this.collection.once('sync', this.loadAnnouncements, this)
  }

  loadAnnouncements () {
    this.announcements = this.collection
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

  search () {
    const term = this.getValEl().find('input').val()
    if (term === this.lastTerm) {
      return
    }
    this.lastTerm = term
    this.getSearchResultsEl().empty().append('Searching')
    this.collection = new CocoCollection(this.announcements.filter((ann) => {
      return ann.get('name').toLowerCase().includes(term.toLowerCase())
    }), { model: Announcement })
    console.log(this.collection)
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
