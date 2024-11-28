const fetchJson = require('./fetch-json')

const postExam = async (options) => {
  return fetchJson('/db/exam', {
    method: 'POST',
    json: options,
  })
}

const getExamById = async (id) => {
  return fetchJson(`/db/exams/${id}`)
}

const getSubmissionsStatus = async (examId) => {
  return fetchJson(`/db/exams/${examId}/submission-status`)
}

module.exports = {
  postExam,
  getExamById,
  getSubmissionsStatus,
}
