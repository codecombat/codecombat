import fetchJson from './fetch-json'

export const getPublicClans = () => fetchJson(`/db/clan/-/public`)

export const getMyClans = () => fetchJson(`/db/user/${me.id}/clans`)

export const getClan = idOrSlug => fetchJson(`/db/clan/${idOrSlug}`)

export const joinClan = clanId => fetchJson(`/db/clan/${clanId}/join`, {
  method: 'PUT'
})

export const leaveClan = clanId => fetchJson(`/db/clan/${clanId}/leave`, {
  method: 'PUT'
})
