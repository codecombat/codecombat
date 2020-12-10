import fetchJson from './fetch-json'

export const getPublicClans = () => fetchJson(`/db/clan/-/public`)

export const getMyClans = () => fetchJson(`/db/user/${me.id}/clans`)

export const getClan = idOrSlug => fetchJson(`/db/clan/${idOrSlug}`)

// TODO figure this POST request out?
// export const getNamesInClan = () => fetchJson(`/db/user/-/names`, {
//   data: { ids: clanIDs }
// })
