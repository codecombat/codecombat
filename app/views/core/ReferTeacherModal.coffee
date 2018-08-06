ModalView = require 'views/core/ModalView'
State = require 'models/State'

module.exports = class ReferTeacherModal extends ModalView
    id: 'refer-teacher-modal'
    template: require 'templates/modal/refer-teacher-modal'
    closeButton: true

    events:
        'change input[name="name-input"]': 'onChangeName'
        'click .back-btn': 'onClickBackButton'

    initialize: ->
        @state = new State({
            name: '',
            teacherEmail: '',
            customText: ''
        })
        @listenTo @state, 'all', _.debounce(@render)

    onChangeName: (e) ->
        console.log("Changed", e.value)
    
    onClickBackButton: ->
        @trigger 'nav-back'
