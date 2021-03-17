import fetchJson from './fetch-json'

export const fetchAllStudentNames = (teacherId) => {
  return fetchJson(`/db/teacher/${teacherId}/allStudentNames`)
}
