require("app/styles/modal/parent-refer-teacher-modal.sass")
ModalView = require 'views/core/ModalView'
State = require 'models/State'
contact = require 'core/contact'


module.exports = class ParentReferTeacherModal extends ModalView
    id: 'parent-refer-teacher-modal'
    template: require 'templates/modal/parent-refer-teacher-modal'
    closeButton: true

    events:
        'submit': 'sendEmail'

    initialize: ->
        @state = new State({
            name: '',
            teacherEmail: '',
            customText: '',
            emailSending: false,
        })
        @listenTo @state, 'all', _.debounce(@render)

    sendEmail: ->
        @state.set({ emailSending: true })
        console.log("Sending email test")
        contact.sendParentTeacherSignup({
            teacherEmail: 'spyr1014@gmail.com',
            parentEmail: 'andrewflashanimator@gmail.com',
            parentName: 'Bob Franky',
            customContent: 'I just think this is absolutely fantastic! \n I want more of this.'
        })
            .then( =>
                @state.set({ emailSending: false })
            )
            .catch( =>
                @state.set({ error: true }))
        
    
