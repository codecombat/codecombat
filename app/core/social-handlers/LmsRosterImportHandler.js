import BackgroundJobApi from 'app/core/api/background-job.js'

// Shared by both the "link a new LMS classroom" flow and the "re-import an
// already-linked LMS classroom" flow, so the background-job create/poll/reload
// sequence only lives in one place.
export default {
  async importClassroom (savedClassroom) {
    const lmsClassroom = savedClassroom.lmsClassroom
    if (!lmsClassroom?.classId || !lmsClassroom?.provider) {
      noty({
        text: 'Classroom is not linked to an LMS classroom',
        type: 'error',
      })
      return
    }
    const job = await BackgroundJobApi.create('oauth2-roster-class', {
      classroomId: savedClassroom._id,
      lmsClassroomId: lmsClassroom.classId,
      provider: lmsClassroom.provider,
    })
    await BackgroundJobApi.pollTillResult(job.job, {
      showNotification: true,
    })
    window.location.reload()
  },
}
