// Usage
// node scripts/find-coco-ozar-diffs.mjs
// All the separate coco/ozar files will be listed in descending order of how many differences they have.
// The difference level can be any number from 1 (identical) to any higher number

import fs from 'fs/promises'
import { globby } from 'globby'
import _ from 'lodash'
import gitDiff from 'git-diff'

(async () => {

  const paths = await globby('app/**/**')
  const filteredPaths = paths
    .filter((i, k) => i.match(/\.ozar\./) && i == paths[k - 1].replace(/\.coco\./, '.ozar.'))
    // .filter(i=>i.match(/\.coffee/))

  const duplications = []
  for (const ozarFile of filteredPaths) {
    const cocoFile = ozarFile.replace(/\.ozar\./, '.coco.')

    const ozarContent = (await fs.readFile(ozarFile)).toString()
    const cocoContent = (await fs.readFile(cocoFile)).toString()

    console.log(ozarFile, cocoFile, '...')
    const time1 = new Date().getTime()

    const diff = await gitDiff(ozarContent, cocoContent)

    if(!diff){
      console.log('NO DIFF', ozarFile, diff)
      continue;
    }

    let diffCount = (diff.match(/^@@\s[+-]\d+,(\d+)\s[+-]\d+,(\d+)/mg) ||[]).map(i=>i.match(/@@\s[+-]\d+,(\d+)\s[+-]\d+,(\d+)/)).map(i=>parseInt(i[1])+parseInt(i[2])).reduce((partialSum, a) => partialSum + a, 0) || 0;

    if(diffCount === 0){
      diffCount = diff.match(/^[-+]/mg) && diff.match(/^[-+]/mg).length || 0
    }

    duplications.push({
      cocoFile,
      ozarFile,
      level: diffCount
    })


    const time2 = new Date().getTime()

    // break;
    console.log(time2 - time1)

  }

  const sortedDuplications = _.sortBy(duplications, 'level').reverse()

  sortedDuplications.forEach(i => console.log(JSON.stringify(i, null, 4)))
  console.log('total files count:', sortedDuplications.length)
})()
