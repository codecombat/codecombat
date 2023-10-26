import momentTz from 'moment-timezone'
import { HTML5_FMT_DATE_LOCAL, HTML5_FMT_TIME_LOCAL } from '../../../core/constants'

function timeZoneDate (date, timeZone) {
  return momentTz(date).tz(timeZone).format(HTML5_FMT_DATE_LOCAL)
}
function timeZoneTime (date, timeZone) {
  return momentTz(date).tz(timeZone).format(HTML5_FMT_TIME_LOCAL)
}

export default {
  methods: {
    convertTimesForUI ({ startDate, endDate, timeZone }) {
      this.startDate = timeZoneDate(startDate, timeZone)
      this.endDate = timeZoneDate(endDate, timeZone)
      this.startTime = timeZoneTime(startDate, timeZone)
      this.endTime = timeZoneTime(endDate, timeZone)
    },
    validateDates ({ initialStartDate, initialEndDate }) {
      const endDate = new Date(`${this.endDate} ${this.endTime}${this.tzOffset}`)
      const startDate = new Date(`${this.startDate} ${this.startTime}${this.tzOffset}`)
      const iStartDate = new Date(initialStartDate)
      const iEndDate = new Date(initialEndDate)

      let errMsg
      if (endDate.getTime() <= startDate.getTime()) {
        errMsg = 'End date must be after start date'
      }
      const timeUpdated = (startDate.getTime() !== iStartDate.getTime()) || (endDate.getTime() !== iEndDate.getTime())
      return { errMsg, timeUpdated, startDate, endDate }
    }
  }
}
