const fetchJson = require('./fetch-json')

const startExam = async (examId, options) => {
  return fetchJson(`/db/user-exams/${examId}/start`, {
    method: 'POST',
    json: options,
  })
}

const submitExam = async (id, options) => {
  return fetchJson(`/db/user-exams/${id}/submit`, {
    method: 'POST',
    json: options,
  })
}

const getUserExam = async (examId) => {
  return fetchJson(`/db/user-exams/${examId}`)
}

module.exports = {
  startExam,
  submitExam,
  getUserExam,
}
