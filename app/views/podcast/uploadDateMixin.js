const moment = window.moment

export default {
  methods: {
    getUploadDate (date) {
      return moment(date).format('MMM DD YYYY')
    }
  }
}
