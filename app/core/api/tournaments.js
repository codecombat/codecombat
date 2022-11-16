const fetchJson = require('./fetch-json')

const postTournament = (options) => {
  return fetchJson('/db/tournament', {
    method: 'POST',
    json: options
  })
}

const putTournament = (options) => {
  return fetchJson(`/db/tournament/${options._id}`, {
    method: 'PUT',
    json: options
  })
}

const getTournamentsByMember = memberId => fetchJson(`/db/tournaments?memberId=${memberId}`)

module.exports = {
  postTournament,
  putTournament,
  getTournamentsByMember
}
