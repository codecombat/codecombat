import fetchJson from './fetch-json'

export const getOutcomesReportStats = (kind, orgIdOrSlug, { includeSubOrgs, country, startDate, endDate, newReport }) => {
  let url = `/db/outcomes-reports/${kind}/${orgIdOrSlug}/stats?includeSubOrgs=${includeSubOrgs || false}`
  if (newReport) {
    url += '&new_report=true'
  }
  if (kind === 'administrative-region') {
    url += `&country=${country || 'US'}`
  }
  if (startDate) {
    url += `&startDate=${startDate}`
  }
  if (endDate && endDate !== moment(new Date()).format('YYYY-MM-DD')) {
    url += `&endDate=${endDate}`
  }
  return fetchJson(url)
}
