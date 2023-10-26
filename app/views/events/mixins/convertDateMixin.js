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
    }
  }
}
