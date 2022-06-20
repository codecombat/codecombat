import moment from 'moment'

export default {
  methods: {
    getUploadDate (date) {
      return moment(date).format('MMM DD YYYY')
    }
  }
}
