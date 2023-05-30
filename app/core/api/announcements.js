import fetchJson from './fetch-json';


export default {
  getNew: () => fetchJson('/db/user/announcements/new', {method: 'POST'}),
  getList: (options) => {
    let url = '/db/user/announcements';
    if(options && options.skip ) {
      url += `?skip=${options.skip}`
    }
    return fetchJson(url)
  },
  read: (options) => {
    return fetchJson('/db/user/announcement/read', {
      method: 'POST',
      json: options
    })
  }
};
