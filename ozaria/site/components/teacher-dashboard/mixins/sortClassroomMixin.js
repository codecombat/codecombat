import moment from 'moment'

export default {
  methods: {
    classroomSortById (a, b) {
      return moment(parseInt(b._id.substring(0, 8), 16) * 1000).diff(moment(parseInt(a._id.substring(0, 8), 16) * 1000))
    },
  },
}
