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

const getUserExam = async (examId, includeArchived) => {
  let url = `/db/user-exams/${examId}`
  if (includeArchived) {
    url += '?includeArchived=true'
  }
  return fetchJson(url)
}

module.exports = {
  startExam,
  submitExam,
  getUserExam,
}
