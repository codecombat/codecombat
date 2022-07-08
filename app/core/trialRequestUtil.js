const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])
const ROOT_LEVEL_KEYS = ['_id', 'type', 'status', 'reviewer', 'applicant'];

function getNcesData() {
  return SCHOOL_NCES_KEYS.reduce((prev, curr) => setAndReturn(prev, `nces_${curr}`, ''), {})
}

function getRootLevelData() {
  return ROOT_LEVEL_KEYS.reduce((prev, key) => setAndReturn(prev, key, ''), {})
}

function setAndReturn(obj, key, val) {
  obj[key] = val;
  return obj;
}

module.exports = {
  getNcesData,
  getRootLevelData,
  SCHOOL_NCES_KEYS,
  ROOT_LEVEL_KEYS
}
