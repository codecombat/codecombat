const fetchJson = require('./fetch-json')

const postExam = async (options) => {
  return fetchJson('/db/exam', {
    method: 'POST',
    json: options,
  })
}

const getExamById = async (id) => {
  return fetchJson(`/db/exam/${id}`)
}

module.exports = {
  postExam,
  getExamById,
}
