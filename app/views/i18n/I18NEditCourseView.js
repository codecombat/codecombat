const I18NEditModelView = require('./I18NEditModelView')
const Course = require('models/Course')

// TODO: Apply these changes to all i18n views if it proves to be more reliable

const I18NEditCourseView = class I18NEditCourseView extends I18NEditModelView {
  static initClass () {
    this.prototype.id = 'i18n-edit-course-view'
    this.prototype.modelClass = Course
  }

  buildTranslationList () {
    const lang = this.selectedLanguage

    // name, description, shortName
    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      if (name) {
        this.wrapRow('Course short name', ['name'], name, i18n[lang]?.name, [])
      }

      const description = this.model.get('description')
      if (description) {
        this.wrapRow('Course description', ['description'], description, i18n[lang]?.description, [])
      }

      // Update the duration text that appears in the curriculum guide
      const durationI18n = this.model.get('duration')?.i18n
      if (durationI18n) {
        const total = this.model.get('duration').total
        if (total) {
          this.wrapRow(
            'Duration Total',
            ['total'],
            total,
            durationI18n[lang]?.total,
            ['duration'],
          )
        }

        const inGame = this.model.get('duration').inGame
        if (inGame) {
          this.wrapRow(
            'Duration inGame',
            ['inGame'],
            inGame,
            durationI18n[lang]?.inGame,
            ['duration'],
          )
        }

        const totalTimeRange = this.model.get('duration').totalTimeRange
        if (totalTimeRange) {
          this.wrapRow(
            'Duration totalTimeRange',
            ['totalTimeRange'],
            totalTimeRange,
            durationI18n[lang]?.totalTimeRange,
            ['duration'],
          )
        }
      }

      const cstaStandards = this.model.get('cstaStandards') || []
      for (let i = 0; i < cstaStandards.length; i++) {
        const standard = cstaStandards[i]
        const standardI18n = standard.i18n
        if (standardI18n) {
          this.wrapRow('CSTA: Name', ['name'], standard.name, standardI18n[lang]?.name, ['cstaStandards', i])
          this.wrapRow('CSTA: Description', ['description'], standard.description, standardI18n[lang]?.description, ['cstaStandards', i])
        }
      }

      // Handle i18n for course modules
      const modules = this.model.get('modules')
      if (modules) {
        Object.entries(modules).forEach(([moduleKey, moduleData]) => {
          const moduleI18n = moduleData.i18n || {}

          // Handle i18n for module name
          if (moduleData.name) {
            this.wrapRow(
              `Module ${moduleKey}: Name`,
              ['name'],
              moduleData.name,
              moduleI18n[lang]?.name,
              ['modules', moduleKey],
            )
          }

          // Handle i18n for module duration
          if (moduleData.duration) {
            const durationProps = ['total', 'inGame', 'totalTimeRange']
            durationProps.forEach(prop => {
              if (moduleData.duration[prop]) {
                this.wrapRow(
                  `Module ${moduleKey}: Duration ${prop}`,
                  [prop],
                  moduleData.duration[prop],
                  moduleI18n[lang]?.duration?.[prop],
                  ['modules', moduleKey, 'duration'],
                )
              }
            })
          }

          // Handle i18n for lessonSlidesUrl
          if (moduleData.lessonSlidesUrl) {
            if (typeof moduleData.lessonSlidesUrl === 'string') {
              // If lessonSlidesUrl is a string, treat it as a single URL
              this.wrapRow(
                `Module ${moduleKey}: Lesson Slides URL`,
                ['lessonSlidesUrl'],
                moduleData.lessonSlidesUrl,
                moduleI18n[lang]?.lessonSlidesUrl,
                ['modules', moduleKey],
              )
            } else if (typeof moduleData.lessonSlidesUrl === 'object') {
              // If lessonSlidesUrl is an object, handle each language separately
              Object.entries(moduleData.lessonSlidesUrl).forEach(([urlLang, url]) => {
                this.wrapRow(
                  `Module ${moduleKey}: Lesson Slides URL (${urlLang})`,
                  ['lessonSlidesUrl', urlLang],
                  url,
                  moduleI18n[lang]?.lessonSlidesUrl?.[urlLang],
                  ['modules', moduleKey],
                )
              })
            }
          }
        })
      }
    }
  }
}

I18NEditCourseView.initClass()

module.exports = I18NEditCourseView
