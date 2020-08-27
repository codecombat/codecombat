import { helpers, required, email, requiredIf, minLength, maxLength, not } from 'vuelidate/lib/validators'
import { getSchoolFormFieldsConfig } from './signUpConfig'

const User = require('models/User')

// Any custom validations

const uniqueEmail = async (email) => {
  if (email) {
    const { exists } = await User.checkEmailExists(email)
    return !exists
  }
  return true
}

// Below functions contain validations needed for each of the fields, in each of the forms of the educator signup flow

export const basicInfoValidations = {
  firstName: {
    required
  },
  lastName: {
    required
  },
  email: {
    required,
    email,
    uniqueEmail
  },
  password: {
    required,
    minLength: minLength(8),
    maxLength: maxLength(64),
    repeating: not(helpers.regex('repeating', /([\s\S])\1\1/))
  }
}

export const roleInfoValidations = {
  role: {
    required
  },
  country: {
    required
  }
}

export const schoolLocationInfoValidations = function (country, role, isChinaServer = false) {
  const formFieldConfig = getSchoolFormFieldsConfig(country, role, isChinaServer)
  return {
    organization: {
      required: requiredIf(() => formFieldConfig.organization.required)
    },
    district: {
      required: requiredIf(() => formFieldConfig.district.required)
    },
    city: {
      required: requiredIf(() => formFieldConfig.city.required)
    },
    state: {
      required: requiredIf(() => formFieldConfig.state.required)
    }
  }
}

export const educatorOtherInfoValidations = function (country, role, isChinaServer = false) {
  const formFieldConfig = getSchoolFormFieldsConfig(country, role, isChinaServer)
  return {
    phoneNumber: {
      required: requiredIf(() => formFieldConfig.phoneNumber.required)
    },
    numStudents: {
      required: requiredIf(() => formFieldConfig.numStudents.required)
    }
  }
}

// Messages to display for any validation failure
export const validationMessages = {
  errorRequired: {
    i18n: 'form_validation_errors.required'
  },
  errorInvalidEmail: {
    i18n: 'form_validation_errors.invalidEmail'
  },
  errorInvalidPhone: {
    i18n: 'form_validation_errors.invalidPhone'
  },
  errorEmailExists: {
    i18n: 'form_validation_errors.emailExists'
  }
}
