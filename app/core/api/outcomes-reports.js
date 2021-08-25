import fetchJson from './fetch-json'

export const getOutcomesReportStats = (kind, orgIdOrSlug, { includeSubOrgs, country }) => {
  let url = `/db/outcomes-reports/${kind}/${orgIdOrSlug}/stats?includeSubOrgs=${includeSubOrgs || false}`
  if (kind === 'administrative-region') {
    url += `&country=${country || 'US'}`
  }
  return fetchJson(url)
}
