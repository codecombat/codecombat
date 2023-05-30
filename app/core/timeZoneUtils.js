export default (moment) => {
  return {
    changeTimeZone (dateString, format, from, to, toFormat = format) {
      moment.locale('en')
      const date = moment.tz(dateString, format, from)
      const dateInNewTimezone = date.clone().tz(to)
      if (toFormat) {
        return dateInNewTimezone.format(toFormat)
      }
      return dateInNewTimezone
    }
  }
};
