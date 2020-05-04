import { EDUCATOR_ROLES, COUNTRIES } from './constants'

const getHiddenFieldsUS = function () {
  const hiddenFields = {}
  hiddenFields[EDUCATOR_ROLES.TEACHER.value] = ['district', 'city']
  hiddenFields[EDUCATOR_ROLES.PRINCIPAL.value] = ['district', 'city']
  hiddenFields[EDUCATOR_ROLES.TECH_COORD.value] = ['city']
  hiddenFields[EDUCATOR_ROLES.CURR_SPEC_ADV.value] = ['city']
  hiddenFields[EDUCATOR_ROLES.SUPERIN.value] = ['organization', 'city']
  return hiddenFields
}

const getOptionalFieldsUS = function () {
  const optionalFields = {}
  optionalFields[EDUCATOR_ROLES.TEACHER.value] = ['phoneNumber']
  optionalFields[EDUCATOR_ROLES.PRINCIPAL.value] = ['phoneNumber']
  optionalFields[EDUCATOR_ROLES.TECH_COORD.value] = ['organization', 'phoneNumber']
  optionalFields[EDUCATOR_ROLES.CURR_SPEC_ADV.value] = ['organization', 'phoneNumber']
  optionalFields[EDUCATOR_ROLES.SUPERIN.value] = ['phoneNumber']
  return optionalFields
}

// make everything visible, and required by default
const defaultFieldsConfig = function () {
  return {
    organization: {
      visible: true,
      required: true
    },
    district: {
      visible: true,
      required: true
    },
    city: {
      visible: true,
      required: true
    },
    state: {
      visible: true,
      required: true
    },
    phoneNumber: {
      visible: true,
      required: true
    },
    numStudents: {
      visible: true,
      required: true
    }
  }
}

// Returns the config (visible and required property) for each of the school form fields, for a given country and role
export const getSchoolFormFieldsConfig = function (country, role, isChinaServerSignup = false) {
  const fields = defaultFieldsConfig()

  let hiddenFields = []
  let optionalFields = []

  if (role === EDUCATOR_ROLES.PARENT.value) {
    hiddenFields = ['organization', 'district', 'city', 'phoneNumber', 'numStudents']
  } else if (country === COUNTRIES.US) {
    hiddenFields = (getHiddenFieldsUS() || {})[role]
    optionalFields = (getOptionalFieldsUS() || {})[role]
  } else {
    hiddenFields = ['district', 'phoneNumber']
  }

  // Override values for china server
  if (isChinaServerSignup) {
    // phoneNumber required and visible
    hiddenFields = hiddenFields.filter(field => !['phoneNumber'].includes(field))
    optionalFields = optionalFields.filter(field => !['phoneNumber'].includes(field))
  }

  Object.keys(fields).forEach((key) => {
    if (hiddenFields.includes(key)) {
      fields[key].visible = false
      fields[key].required = false
    }
  })
  Object.keys(fields).forEach((key) => {
    if (optionalFields.includes(key)) {
      fields[key].required = false
    }
  })

  return fields
}

// Returns the list of educator roles to display in the signup form
export const getEducatorRoles = function (isChinaServerSignup = false) {
  if (isChinaServerSignup) {
    return [EDUCATOR_ROLES.TEACHER, EDUCATOR_ROLES.PARENT]
  } else {
    return Object.values(EDUCATOR_ROLES)
  }
}
