require('app/styles/courses/classroom-announcement-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-announcement-modal'
DOMPurify = require 'dompurify';

module.exports = class ClassroomAnnouncementModal extends ModalView
  id: 'classroom-announcement-modal'
  template: template

  events:
    'click #close-modal': 'hide'

  constructor: (options) ->
    super(options)
    @announcement = DOMPurify.sanitize marked(options.announcement)
