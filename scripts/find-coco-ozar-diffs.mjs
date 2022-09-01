// Usage
// node scripts/find-coco-ozar-diffs.mjs
// All the separate coco/ozar files will be listed in descending order of how many differences they have.
// The difference level can be any number from 1 (identical) to any higher number

import fs from 'fs/promises'
import { globby } from 'globby'
import * as Diff from 'diff'
import _ from 'lodash'

(async () => {

  const paths = await globby('app/**/**')
  const filteredPaths = paths
    .filter((i, k) => i.match(/\.ozar\./) && i == paths[k - 1].replace(/\.coco\./, '.ozar.'))

  const duplications = []
  for (const ozarFile of filteredPaths) {
    const cocoFile = ozarFile.replace(/\.ozar\./, '.coco.')

    const ozarContent = (await fs.readFile(ozarFile)).toString()
    const cocoContent = (await fs.readFile(cocoFile)).toString()

    const diff = Diff.diffLines(ozarContent, cocoContent)
    duplications.push({
      cocoFile,
      ozarFile,
      level: diff.length,
    })

  }

  const sortedDuplications = _.sortBy(duplications, 'level').reverse();

  sortedDuplications.forEach(i => console.log(i))
  console.log('total files count:', sortedDuplications.length)
})()
