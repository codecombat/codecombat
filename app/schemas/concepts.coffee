# NOTE: 'automatic' is whether rob's auto-tagger can find it.
product = COCO_PRODUCT ? 'codecombat'
isCodeCombat = product == 'codecombat'

dupList = [
  {concept: 'basic_syntax', name: 'Basic Syntax', description: 'Using programming language rules.', automatic: true, tagger: '*'} #ozaria
  {concept: 'variables', name: 'Variables', description: 'Storing and updating data in variables.', automatic: true, tagger: 'VariableDeclaration'}
  {concept: 'algorithms', name: 'Algorithms', description: 'Writing sequences of code.', automatic: false}
]
if isCodeCombat
  dupList = [
    {concept: 'algorithms', name: '', description: '', automatic: false, deprecated: true} #coco
    {concept: 'variables', name: 'Variables', description: 'Storing data in variables.', automatic: true, tagger: 'VariableDeclaration'} #coco
    {concept: 'basic_syntax', name: 'Basic Syntax', description: 'Writing code of any sort.', automatic: true, tagger: '*'} #coco
  ]

concepts = dupList.concat [
  
]

module.exports = concepts
