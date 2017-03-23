SchoolInfoPanel = require('views/core/CreateAccountModal/teacher/SchoolInfoPanel')
window.SchoolInfoPanel = SchoolInfoPanel
TeacherSignupStoreModule = require('views/core/CreateAccountModal/teacher/TeacherSignupStoreModule')

describe 'SchoolInfoPanel', ->
  describe 'methods', ->
    describe 'commitValues', ->
      it 'converts nces data to strings', ->
        component = {
          $store: {
            state: { modal: _.cloneDeep(TeacherSignupStoreModule.state) }
            commit: jasmine.createSpy()
          }
          commitValues: SchoolInfoPanel.methods.commitValues
          data: SchoolInfoPanel.data
        }
        _.assign(component, component.data(), {
          nces_district_schools: 20
          nces_district_students: 524
          nces_students: 203
        })
        component.commitValues()
        expect(component.$store.commit.calls.count()).toBe(1)
        expect(component.$store.commit.calls.argsFor(0)).toDeepEqual([
          'modal/updateTrialRequestProperties',
          {
            city: ""
            country: ""
            district: ""
            nces_district: ""
            nces_district_id: ""
            nces_district_schools: "20"
            nces_district_students: '524'
            nces_id: ""
            nces_name: ""
            nces_phone: ""
            nces_students: "203"
            organization: ""
            state: ""
          }
        ])
        
