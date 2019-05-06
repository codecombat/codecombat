<template lang="pug">
  #apcsp-landing
    h1.text-center
      | Teaching AP <sup>®</sup> Computer Science Principles?
    h2.text-center We’ve got you covered.

    #endorsement
      img#ap-provider-badge(src="/images/pages/apcsp/APCSP_ProviderBadge_lg.png")
      div CodeCombat is recognized by the College Board as an endorsed provider of curriculum and professional development for AP<sup>®</sup> Computer Science Principles (AP CSP). This endorsement affirms that all components of CodeCombat‘s offerings are aligned to the AP Curriculum Framework standards and the AP CSP assessment. Using an endorsed provider affords schools access to resources including an AP CSP syllabus pre-approved by the College Board’s AP Course Audit, and officially recognized professional development that prepares teachers to teach AP CSP.

    p Are you teaching AP<sup>®</sup> Computer Science Principles at your high school for the 2019-2020 school year? CodeCombat’s comprehensive curriculum and professional development program are all you need to offer College Board’s newest computer science course to your students.

    p AP<sup>®</sup> Computer Science Principles spotlights how computing is changing the world, and provides ample opportunity for students from all backgrounds to connect abstract concepts to real-world implications of the field. Teachers can use our AP<sup>®</sup> CSP Curriculum and Professional Development Hub as their primary resource for teaching the course and preparing students for the AP<sup>®</sup> exam.

    p We’ve designed our resources to support teachers regardless of their programming experience, enabling every educator to facilitate this course with confidence. Our team at CodeCombat will be with you every step of the way.

    h4 CodeCombat’s curriculum features:
    ul
      li A full end-to-end curricular solution for teaching AP<sup>®</sup> Computer Science Principles.
      li Free, self-paced professional development with oversight from our educational experts.
      li Guidance on all aspects of the course, including the AP<sup>®</sup> CSP Performance Tasks and how to utilize practice opportunities to set your students up for success.
      li Real, typed code in either JavaScript or Python to support your students’ creativity.

    p We are currently accepting teachers for our summer professional development cohort in preparation for the 2018-2019 school year. Request access to our curriculum to learn more.

    .text-center
      button.btn.btn-primary.btn-lg.text-center(
        data-toggle="modal"
        data-target="#request-access-modal"
      )
        | Request Access

    #request-access-modal.modal.fade
      .modal-dialog
        .modal-content.style-flat
          .modal-header
            .button.close(type="button", data-dismiss="modal", aria-hidden="true") &times;
            h3 Request AP<sup>®</sup> CS Principles Access

          .modal-body
            div(v-if='state === "sending"') Sending...
            div(v-else-if='state === "sent"') Thank you for expressing interest in our curriculum for AP<sup>®</sup> Computer Science Principles. Our school specialists will be in touch shortly with next steps.
            form(@submit.prevent="onSubmit" v-else)
              .form-group
                label(for="name") Name
                input#name.form-control(v-model="name" autocomplete="name")
              .form-group
                label(for="email") Email
                input#email.form-control(type="email" v-model="email" autocomplete="email")
              nces-search-input(@navSearchChoose="onChooseSchool", :initialValue="organization", label="School", @updateValue="onUpdateSchoolValue")
              .form-group
                label(for="num-apcsp-students") Estimated # of AP<sup>®</sup> CSP students for 2018-2019 school year
                input#num-apcsp-students.form-control(type="number", v-model="numAPCSPStudents")
              .form-group
                label Are you currently teaching or have you taught an AP<sup>®</sup> CSP course in the past?
                .radio-inline
                  label
                    input(type="radio", name="currentlyTeaching" value="yes", v-model="currentlyTeaching" v-bind:value="true")
                    | Yes
                .radio-inline
                  label
                    input(type="radio", name="currentlyTeaching" value="no", v-model="currentlyTeaching" v-bind:value="false")
                    | No
              .form-group
                label Will you be teaching AP<sup>®</sup> CSP in the 2019-2020 school year? 
                .radio-inline
                  label
                    input(type="radio", name="willTeachNextYear" value="yes", v-model="willTeachNextYear" v-bind:value="true")
                    | Yes
                .radio-inline
                  label
                    input(type="radio", name="willTeachNextYear" value="no", v-model="willTeachNextYear" v-bind:value="false")
                    | No
              .form-group
                label(for="apcsp-experience") Which AP<sup>®</sup> CSP resources have you used in the past? 
                textarea#apcsp-experience.form-control(v-model="apcspResourcesUsedPreviously")

          .modal-footer(v-if='state === "entering"')
            button.btn.btn-primary.btn-lg(
            type="button",
            aria-hidden="true",
            @click="onSubmit",
            :disabled="submitButtonDisabled"
            ) Submit
            
    hr

    h4.text-center
      strong
        | Curriculum Specifications

    h5 Programming Languages
    p CodeCombat’s curiculum can be used to learn programming in either JavaScript or Python, which teachers will choose upon creation of their classroom inside the CodeCombat platform.

    h5 Teacher Verification
    p Teachers who are approved through CodeCombat’s verification process will be given access to our full AP® Computer Science Principles curriculum, including all professional development and assessment materials. The verification process is free, and is designed to maximize our professional development efforts.

    h5 Minimum Hardware/Software Specifications
    p CodeCombat runs best on computers with at least 4GB of RAM, on a modern browser such as Chrome, Safari, Firefox, or Edge. Chromebooks with 2GB of RAM may have minor graphics issues in courses beyond Computer Science 3, though there should be minimal issues with the recommended content for AP® Computer Science Principles as outlined. A minimum of 200 Kbps bandwidth per student is required, although 1+ Mbps is recommended.

    h5 Professional Development
    p Our professional development materials are made available to all verified teachers at no cost. Professional development is self-directed and self-paced, taking place online and in collaborative forums where teachers can ask questions and participate in discussions with other verified teachers and CodeCombat content experts. We strongly encourage all teachers to go through professional development before using CodeCombat as their AP® Computer Science Principles curriculum, and we provide support throughout the year as their classes progress through the curriculum.

    h5 Student Licenses
    p
      | In order for teachers to be able to assign the required CodeCombat courses to students in their class, each student will need a License. Information on license pricing and structure can be obtained by speaking to CodeCombat’s school specialists (email
      =" "
      a(mailto="schools@codecombat.com") schools@codecombat.com
      =""
      | ). We recommend that licenses are obtained by early August of the coming school year so students can begin as early as the first day of the fall semester.

    p#registered
      i AP<sup>®</sup> and Advanced Placement<sup>®</sup> are registered trademarks of the College Board. Used with permission.


</template>

<script lang="coffee">
  api = require 'core/api'
  NcesSearchInput = require 'views/core/CreateAccountModal/teacher/NcesSearchInput'
  
  module.exports = Vue.extend({
    data: -> {
      email: '',
      name: '',
      organization: '',
      nces_phone : '',
      nces_students : '',
      nces_district_students : '',
      nces_district_schools : '',
      nces_district_id : '',
      nces_district : '',
      nces_name : '',
      nces_id : '',
      numAPCSPStudents: '',
      apcspResourcesUsedPreviously: '',
      hasPrepaids: '',
      state: 'entering' # or 'sending', 'sent'
      currentlyTeaching: null
      willTeachNextYear: null
    }
    
    components: {
      NcesSearchInput
    }
    
    methods:
      onSubmit: ->
        lines = []
        props = { siteOrigin: 'apcsp landing' }
        _.forIn(@$data, (value, key) =>
          return if key in ['state']
          if value
            props[key] = value
        )
        api.trialRequests.post({
          type: 'course'
          properties: props
        }).then(() => @state = 'sent')
        
      onChooseSchool: (displayKey, choice) ->
        @organization = choice.name
        _.forIn(choice, (value, key) =>
          @["nces_#{key}"] = value
        )

      onUpdateSchoolValue: (name, newValue) ->
        @organization = newValue
      
    computed:
      submitButtonDisabled: ->
        not _.every([@email, @name, @organization, @willTeachNextYear?, @currentlyTeaching?, @numAPCSPStudents])

    created: ->
      api.trialRequests.getOwn().then((trialRequests) =>
        trialRequests = _.sortBy(trialRequests, (t) -> t.id)
        lastTrialRequest = _.last(trialRequests)
        properties = lastTrialRequest?.properties || {}
        _.assign(@, _.pick(properties, 'email', 'organization'))
        @name = _.string.trim((properties.firstName || '') + ' ' + (properties.lastName || ''))
      )
      unless me.isAnonymous()
        api.prepaids.getOwn().then((prepaids) =>
          @hasPrepaids = _.uniq(prepaids.map((p) -> p.type)).join(', ')
        )
  })

</script>

<style lang="sass">
  #apcsp-landing
    max-width: 800px
    margin: 0 auto

    h1
      margin: 30px 0 0px
      font-size: 36px

    h2
      margin-bottom: 20px

    h3
      margin: 30px 0 10px

    h4
      margin: 10px 0

    h5
      margin: 30px 0 5px
      font-weight: normal

    ul
      margin: 10px 0 25px 0

    p
      margin: 0 0 25px

    #endorsement
      margin: 30px 0
      font-style: italic
      display: flex
      background-color: #f7f7f7
      border: 1px solid #bbbbbb
      padding: 20px
      font-size: 14px
      line-height: 22px

    #ap-provider-badge
      width: 150px
      margin-right: 30px
      align-self: center

    #registered
      margin-top: 60px
      font-size: 16px
      
    .modal h3
      margin-top: 0
  
    .modal span
      font-weight: bold
</style>
