import Classroom from 'models/Classroom'

export default {
  methods: {
    isCodeNinjaClubCamp (classroom) {
      return Classroom.codeNinjaClassroomTypes().map(type => type.id).includes(classroom?.type)
    },
  },
}
