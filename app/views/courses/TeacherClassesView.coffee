RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-classes-view'
Classrooms = require 'collections/Classrooms'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
User = require 'models/User'
utils = require 'core/utils'

module.exports = class TeacherClassesView extends RootView
  id: 'teacher-classes-view'
  template: template
  
  events:
    'click .edit-classroom': 'onClickEditClassroom'

  constructor: (options) ->
    super(options)
    @classrooms = new Classrooms()
    @classrooms.fetchMine()
    @listenToOnce @classrooms, 'sync', @afterSync
    
  afterSync: () =>
    @capitalizeLanguageNames(@classrooms)
    @render()
    
  capitalizeLanguageNames: (classrooms) =>
    classrooms.forEach (classroom) =>
      language = classroom.get('aceConfig').language
      capitalLanguage = utils.capitalLanguages[language]
      classroom.capitalLanguage = capitalLanguage
    
  onClickEditClassroom: (e) =>
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
