ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/core/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
Classroom = require 'models/Classroom'
errors = require 'core/errors'
# COPPADenyModal = require 'views/core/COPPADenyModal'
utils = require 'core/utils'


module.exports = class ChooseAccountTypeView extends ModalView
  id: 'create-account-modal'
  template: template

  events:
    'click .teacher-path-button': -> @trigger 'choose-path', 'teacher'
    'click .student-path-button': -> @trigger 'choose-path', 'student'
    'click .individual-path-button': -> @trigger 'choose-path', 'individual'
  
  # initialize: ->
    
    
