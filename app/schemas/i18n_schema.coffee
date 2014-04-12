#this file will hold the experimental JSON schema for i18n
c = require './schemas'

languageCodeArrayRegex = c.generateLanguageCodeArrayRegex()


ExampleSchema = {
  title: "Example Schema",
  description:"An example schema",
  type: "object",
  properties: {
    text: {
      title: "Text",
      description: "A short message to display in the dialogue area. Markdown okay.",
      type: "string",
      maxLength: 400
    },
    i18n: {"$ref": "#/definitions/i18n"}
  },

  definitions: {
    i18n: {
      title: "i18n",
      description: "The internationalization object",
      type: "object",
      patternProperties: {
        languageCodeArrayRegex: {
          additionalProperties: false,
          properties: {
          #put the translatable properties here
          #if it is possible to not include i18n with a reference
          # to #/properties, you could just do
          properties: {"$ref":"#/properties"}
           # text: {"$ref": "#/properties/text"}
          }
          default: {
            title: "LanguageCode",
            description: "LanguageDescription"
          }
        }
      }
    }
  },

}

#define a i18n object type for each schema, then have the i18n have it's oneOf check against
#translatable schemas of that object