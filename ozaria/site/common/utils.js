import RandomSeed from 'random-seed'
import storage from "../../../app/core/storage";

function getDateString () {
  const date = new Date()

  const mm = date.getMonth() + 1
  const dd = date.getDate()

  return [
    date.getFullYear(),
    (mm > 9 ? '' : '0') + mm,
    (dd > 9 ? '' : '0') + dd
  ].join('')
}

export function deterministicShuffleForUserAndDay (user, originalArray) {
  if (originalArray.length < 2) return originalArray
  const rand = new RandomSeed(`${getDateString()}${user.id}`)

  let shuffledArray, array;
  do {
    shuffledArray = []
    array = _.cloneDeep(originalArray)
    while (array.length > 0) {
      const element = rand.range(array.length)

      shuffledArray.push(
        array.splice(element, 1)[0]
      )
    }
  } while (_.isEqual(shuffledArray, originalArray))

  return shuffledArray
}

export function getDisplayPermission (permission) {
  const display = permission?.toLowerCase()
  return $.i18n.t(`teacher_dashboard.${display}`)
}

function teacherModalSeenKey (teacherId) {
  return `seen-teacher-details-modal_${teacherId}`
}

export function hasSeenTeacherDetailModalRecently (teacherId) {
  return storage.load(teacherModalSeenKey(teacherId))
}

export function markTeacherDetailsModalAsSeen (teacherId) {
  const HRS_12 = 60 * 12;
  storage.save(teacherModalSeenKey(teacherId), true, HRS_12)
}
