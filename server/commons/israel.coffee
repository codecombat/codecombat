jwt = require 'jsonwebtoken'
config = require '../../server_config'
errors = require '../commons/errors'
mssql = require 'mssql'
co = require 'co'

verifyToken = (israelToken) ->
  try
    result = jwt.verify(israelToken, config.israel.jwtSecret)
  catch e
    if e.name is 'JsonWebTokenError'
      throw new errors.UnprocessableEntity('Invalid JWT Token.')
    if e.name is 'TokenExpiredError'
      throw new errors.UnprocessableEntity('Expired JWT Token.')
    if e.name is 'NotBeforeError'
      throw new errors.UnprocessableEntity('Not yet valid JWT Token.')
    throw e
  { aud, iss, district } = result
  unless aud is config.israel.jwtAudience and iss is config.israel.jwtIssuer and district is config.israel.jwtDistrict
    throw new errors.UnprocessableEntity('JWT token info does not match.')

  # properties returned: 'sub' (israel id) and 'type'
  return result

makeFakeTestingToken = ->
  payload = {
    iss: config.israel.jwtIssuer
    aud: config.israel.jwtAudience
    district: config.israel.jwtDistrict
    sub: 'abcdef'
    given_name: 'אברהם',
    sur_name: 'שיינמן',
    mosad: [ '442376' ],
    student_kita: '9',
    student_makbila: '1',
    type: 'student',
  }
  payload = jwt.sign(payload, config.israel.jwtSecret)
  return payload

institutionTeacherName = (institution) -> "IsraelMoE School #{institution} Teacher"

classCode = ({institutionId, gradeLevel, classId}) -> "#{institutionId}#{gradeLevel}#{classId}"

className = ({institutionId, gradeLevel, classId}) -> "מוסד #{institutionId} שכבת גיל #{gradeLevel} כיתה #{classId}"

getIsraelFinalists = co.wrap ->
  console.log 'Test - trying to connect to this SQL database with connection string', config.israel.sqlConnectionString
  result = {}
  try
    pool = yield mssql.connect config.israel.sqlConnectionString
    query = "select * from studentsGmar where code_combat = 1"
    console.log '  Now going to query:', query
    try
      result = yield new mssql.Request().query query
    catch err
      console.error err
      result = err
  catch err
    console.error err
    result = err
  console.log '  Got result:', result
  mssql.close()
  israelIdsToFinalists = {}
  try
    for record in result.recordset
      israelIdsToFinalists[record.HINEXTERNALIDENTIFIER] = record
  catch err
    console.error "  Couldn't parse result.recordset array:", err
  return israelIdsToFinalists

module.exports = {
  verifyToken
  makeFakeTestingToken
  institutionTeacherName
  classCode
  className
  getIsraelFinalists
}
