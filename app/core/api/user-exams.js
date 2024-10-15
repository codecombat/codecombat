const fetchJson = require('./fetch-json')

const startExam = async (options, examId) => {
  return fetchJson(`/db/exam/${examId}/start`, {
    method: 'POST',
    json: options,
  })
}

const submitExam = async (id, options) => {
  return fetchJson(`/db/user.exam/${id}/submit`, {
    method: 'POST',
    json: options,
  })
}

const getUserExam = async (examId) => {
  return fetchJson(`/db/user/exam/${examId}`)
}

module.exports = {
  startExam,
  submitExam,
  getUserExam,
}
