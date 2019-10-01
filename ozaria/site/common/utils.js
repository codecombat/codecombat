import RandomSeed from 'random-seed'

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

export function deterministicShuffleForUserAndDay (user, array) {
  const rand = new RandomSeed(`${getDateString()}${user.id}`)

  const shuffledArray = []
  while (array.length > 0) {
    const element = rand.range(array.length)

    shuffledArray.push(
      array.splice(element, 1)[0]
    )
  }

  return shuffledArray
}
