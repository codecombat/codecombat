require("app/styles/modal/refer-teacher-modal.sass")
ModalView = require 'views/core/ModalView'
State = require 'models/State'


module.exports = class ReferTeacherModal extends ModalView
    id: 'refer-teacher-modal'
    template: require 'templates/modal/refer-teacher-modal'
    closeButton: true

    events:
        'change input[name="name-input"]': 'onChangeName'

    initialize: ->
        @state = new State({
            name: '',
            teacherEmail: '',
            customText: ''
        })
        @listenTo @state, 'all', _.debounce(@render)

    onChangeName: (e) ->
        console.log("Changed", e.value)
    
