import fetchJson from './fetch-json';

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

const publishTournament = (options) => {
  return fetchJson(`/db/tournament/${options.id}/publish`, {
    method: 'PUT',
    json: true
  })
}

const getTournamentsByMember = memberId => fetchJson(`/db/tournaments?memberId=${memberId}`)

export default {
  postTournament,
  putTournament,
  publishTournament,
  getTournamentsByMember
};
