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

module.exports = {
  postExam,
  getExamById,
}
