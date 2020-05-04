/* eslint-env jasmine */
import { getSchoolFormFieldsConfig } from 'ozaria/site/components/sign-up/PageEducatorSignup/common/signUpConfig'
import { EDUCATOR_ROLES, COUNTRIES } from 'ozaria/site/components/sign-up/PageEducatorSignup/common/constants'

const isChinaServer = window.features.china

// Parents, any country
function getExpectedConfigParents () {
  const expectedConfig = {
    visible: ['state'],
    optional: []
  }
  updateConfigForChinaServer(expectedConfig)
  return expectedConfig
}

// Any educator role, non-US country
function getExpectedConfigNonUSEducator () {
  const expectedConfig = {
    visible: ['organization', 'city', 'state', 'numStudents'],
    optional: []
  }
  updateConfigForChinaServer(expectedConfig)
  return expectedConfig
}

// Teacher/Principal, US
function getExpectedConfigUSTeacher () {
  const expectedConfig = {
    visible: ['organization', 'state', 'phoneNumber', 'numStudents'],
    optional: ['phoneNumber']
  }
  updateConfigForChinaServer(expectedConfig)
  return expectedConfig
}

// Tech coordinator/Advisor, US
function getExpectedConfigUSTechCoord () {
  const expectedConfig = {
    visible: ['organization', 'district', 'state', 'phoneNumber', 'numStudents'],
    optional: ['organization', 'phoneNumber']
  }
  updateConfigForChinaServer(expectedConfig)
  return expectedConfig
}

// Superintendent, US
function getExpectedConfigUSSuperint () {
  const expectedConfig = {
    visible: ['district', 'state', 'phoneNumber', 'numStudents'],
    optional: ['phoneNumber']
  }
  updateConfigForChinaServer(expectedConfig)
  return expectedConfig
}

// Over-writes config for china server to make phone number mandatory
function updateConfigForChinaServer (expectedConfig) {
  if (isChinaServer) {
    if (!expectedConfig.visible.includes('phoneNumber')) {
      expectedConfig.visible.push('phoneNumber')
    }
    expectedConfig.optional = expectedConfig.optional.filter(field => !['phoneNumber'].includes(field))
  }
}

function checkFields (fields, expected) {
  Object.keys(fields).forEach((f) => {
    if (expected.visible.includes(f)) {
      expect(fields[f].visible).toBe(true)
      if (expected.optional.includes(f)) {
        expect(fields[f].required).toBe(false)
      } else {
        expect(fields[f].required).toBe(true)
      }
    } else {
      expect(fields[f].visible).toBe(false)
      expect(fields[f].required).toBe(false)
    }
  })
}

describe('sign up config', () => {
  describe('getSchoolFormFieldsConfig returns the fields config for a given country and role', () => {
    it('role = parent, any country', () => {
      const fields = getSchoolFormFieldsConfig('test', EDUCATOR_ROLES.PARENT.value, isChinaServer)
      const expected = getExpectedConfigParents()
      checkFields(fields, expected)
    })

    it('any educator role, any non-US country', () => {
      const fields = getSchoolFormFieldsConfig('test', EDUCATOR_ROLES.TEACHER.value, isChinaServer)
      const expected = getExpectedConfigNonUSEducator()
      checkFields(fields, expected)
    })

    it('role = teacher/principal, country = US', () => {
      const fields1 = getSchoolFormFieldsConfig(COUNTRIES.US, EDUCATOR_ROLES.TEACHER.value, isChinaServer)
      const expected1 = getExpectedConfigUSTeacher()
      checkFields(fields1, expected1)
      const fields2 = getSchoolFormFieldsConfig(COUNTRIES.US, EDUCATOR_ROLES.PRINCIPAL.value, isChinaServer)
      const expected2 = getExpectedConfigUSTeacher()
      checkFields(fields2, expected2)
    })

    it('role = tech coord/advisor, country = US', () => {
      const fields1 = getSchoolFormFieldsConfig(COUNTRIES.US, EDUCATOR_ROLES.TECH_COORD.value, isChinaServer)
      const expected1 = getExpectedConfigUSTechCoord()
      checkFields(fields1, expected1)
      const fields2 = getSchoolFormFieldsConfig(COUNTRIES.US, EDUCATOR_ROLES.CURR_SPEC_ADV.value, isChinaServer)
      const expected2 = getExpectedConfigUSTechCoord()
      checkFields(fields2, expected2)
    })

    it('role = superintendent, country = US', () => {
      const fields = getSchoolFormFieldsConfig(COUNTRIES.US, EDUCATOR_ROLES.SUPERIN.value, isChinaServer)
      const expected = getExpectedConfigUSSuperint()
      checkFields(fields, expected)
    })
  })
})
