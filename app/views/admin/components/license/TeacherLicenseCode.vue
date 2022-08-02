<script>
import LicenseFormGroup from './LicenseFormGroup'
import LicenseType from './LicenseType'

const PrepaidSchema = require('schemas/models/prepaid.schema')
const api = require('core/api')
const { LICENSE_PRESETS } = require('core/constants')

export default Vue.extend({
  components: {
    LicenseFormGroup,
    LicenseType
  },
  props: ['hide'],
  data () {
    return {
      prepaid: {
        type: 'course',
        startDate: new Date().toISOString(),
        includedCourseIDs: ['1', '2', '3'],
        properties: {
          classroom: 'ObjectId'
        }
      },
      state: 'init',
      licenseType: 'all',
      number: 1,
      duration: 365,
      includedCourseIDs: [],
      endDate: new Date(new Date().setFullYear(new Date().getFullYear() + 1))
    }
  },
  computed: {
    schema () {
      return PrepaidSchema
    },
    licensePresets () {
      return LICENSE_PRESETS
    },
    timeZone () {
      if (features?.chinaInfra)
        return 'Asia/Shanghai'
      else
        return 'America/Los_Angeles'
    },
    moment () {
      return moment
    },
    api () {
      return api
    }
  },
  methods: {
    selectType (t) {
      this.licenseType = t
    },
    selectCourse (c) {
      this.includedCourseIDs = c
    },
    setDate (time) {
      this.endDate = new Date(time)
    },
    addSeats () {
      if (this.number <= 0 || this.duration <= 0 || moment().isAfter(this.endDate))
        return

      let attrs = {
        type: 'course',
        creator: me.id,
        maxRedeemers: this.number,
        endDate: this.endDate.toISOString(),
        startDate: new Date().toISOString(),
        generateActivationCodes: true,
        properties: {
          adminAdded: me.id,
          days: this.duration,
          activatedByTeacher: true
        }
      }
      if (this.licenseType in this.licensePresets) {
        attrs.includedCourseIDs = this.licensePresets[this.licenseType]
      } else if (this.licenseType === 'customize') {
        attrs.includedCourseIDs = this.includedCourseIDs
      }
      this.state = 'creating-prepaid'
      api.prepaids.post(attrs).then((prepaid) => {
        let csvContent = 'Code,Expires\n'
        const ocode = prepaid.code.toUpperCase()
        prepaid.redeemers.forEach((redeemer) => {
          csvContent += `T-${ocode.slice(0, 4)}-${redeemer.code.toUpperCase()}-${ocode.slice(4)},${redeemer.date}\n`
        })
        const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
        window.saveAs(file, `TeacherLicenseCodes-${prepaid._id}-${new Date().toISOString()}.csv`)
        this.state = 'made-prepaid'
        setTimeout(() => { this.state = 'init' }, 5000)
      })
    }
  }
})
</script>
<template lang="pug">
#modal-base-flat.style-flat
  .modal-header
    .button.close(type='button' data-dismiss="modal", aria-hidden="true") &times;
    h3.title
      | Create Teacher License codes
  .body
    .progress.progress-striped.active(v-if="state === 'creating-prepaid'")
      .progress-bar(style="width: 100%")
    .alert.alert-success(v-if="state === 'made-prepaid'") Licenses created!
    #prepaid-code-form.form(v-if="state === 'init'")
      h4.small(style="max-width: 700px") Licenses start at 12am PT on the start date and end at 11:59pm PT on the end date listed.
      license-form-group(label='Number of License Codes', id='seats-input', type="number", name="numbers", min="1", v-model.number="number")
      license-type(@input-type="selectType", @input-course="selectCourse")
      license-form-group(label="Duration", extra=" Days", type='number', name='duration', v-model.number="duration")
      license-form-group(label='Expiration Date' type="date" name="endDate" :value="moment(endDate).tz(timeZone).format('YYYY-MM-DD')" @input="setDate")
      button.btn.btn-primary(@click="addSeats") Create Licenses


</template>

<style scoped lang="scss">
#modal-base-flat{
  background: white;
  color: black;
  box-shadow: 0 3px 9px rgba(0, 0, 0, 0.5);
  padding: 25px;
  font-size: 18px;

  .input {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .buttons {
    width: 600px;
    display: flex;
    justify-content: space-between;
  }
}
</style>