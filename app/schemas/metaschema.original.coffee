# The JSON Schema Core/Validation Meta-Schema, but with titles and descriptions added to make it easier to edit in Treema, and in CoffeeScript

module.exports =
  id: 'metaschema'
  displayProperty: 'title'
  $schema: 'http://json-schema.org/draft-04/schema#'
  title: 'Schema'
  description: 'Core schema meta-schema'
  definitions:
    schemaArray:
      type: 'array'
      minItems: 1
      items: {$ref: '#'}
      title: 'Array of Schemas'
      'default': [{}]
    positiveInteger:
      type: 'integer'
      minimum: 0
      title: 'Positive Integer'
    positiveIntegerDefault0:
      allOf: [{$ref: '#/definitions/positiveInteger'}, {'default': 0}]
    simpleTypes:
      title: 'Single Type'
      'enum': ['array', 'boolean', 'integer', 'null', 'number', 'object', 'string']
    stringArray:
      type: 'array'
      items: {type: 'string'}
      minItems: 1
      uniqueItems: true
      title: 'String Array'
      'default': ['']
  type: 'object'
  properties:
    id:
      type: 'string'
      format: 'uri'
    $schema:
      type: 'string'
      format: 'uri'
      'default': 'http://json-schema.org/draft-04/schema#'
    title:
      type: 'string'
    description:
      type: 'string'
    'default': {}
    multipleOf:
      type: 'number'
      minimum: 0
      exclusiveMinimum: true
    maximum:
      type: 'number'
    exclusiveMaximum:
      type: 'boolean'
      'default': false
    minimum:
      type: 'number'
    exclusiveMinimum:
      type: 'boolean'
      'default': false
    maxLength: {$ref: '#/definitions/positiveInteger'}
    minLength: {$ref: '#/definitions/positiveIntegerDefault0'}
    pattern:
      type: 'string'
      format: 'regex'
    additionalItems:
      anyOf: [
        {type: 'boolean', 'default': false}
        {$ref: '#'}
      ]
    items:
      anyOf: [
        {$ref: '#'}
        {$ref: '#/definitions/schemaArray'}
      ]
      'default': {}
    maxItems: {$ref: '#/definitions/positiveInteger'}
    minItems: {$ref: '#/definitions/positiveIntegerDefault0'}
    uniqueItems:
      type: 'boolean'
      'default': false
    maxProperties: {$ref: '#/definitions/positiveInteger'}
    minProperties: {$ref: '#/definitions/positiveIntegerDefault0'}
    required: {$ref: '#/definitions/stringArray'}
    additionalProperties:
      anyOf: [
        {type: 'boolean', 'default': true}
        {$ref: '#'}
      ]
      'default': {}
    definitions:
      type: 'object'
      additionalProperties: {$ref: '#'}
      'default': {}
    properties:
      type: 'object'
      additionalProperties: {$ref: '#'}
      'default': {}
    patternProperties:
      type: 'object'
      additionalProperties: {$ref: '#'}
      'default': {}
    dependencies:
      type: 'object'
      additionalProperties:
        anyOf: [
          {$ref: '#'}
          {$ref: '#/definitions/stringArray'}
        ]
    'enum':
      type: 'array'
      minItems: 1
      uniqueItems: true
      'default': ['']
    type:
      anyOf: [
        {$ref: '#/definitions/simpleTypes'}
        {
          type: 'array'
          items: {$ref: '#/definitions/simpleTypes'}
          minItems: 1
          uniqueItems: true
          title: 'Array of Types'
          'default': ['string']
        }]
    allOf: {$ref: '#/definitions/schemaArray'}
    anyOf: {$ref: '#/definitions/schemaArray'}
    oneOf: {$ref: '#/definitions/schemaArray'}
    not: {$ref: '#'}
  dependencies:
    exclusiveMaximum: ['maximum']
    exclusiveMinimum: ['minimum']
  'default': {}
