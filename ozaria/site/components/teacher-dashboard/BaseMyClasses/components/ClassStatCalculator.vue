<script>
  /** Given a class id, generates and populates the stats for the class component */
  import { mapGetters } from 'vuex'
  import ClassComponent from '../ClassComponent'

  export default {
    components: {
      ClassComponent
    },

    props: {
      classroomState: {
        type: Object,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        levelSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom',
        sortedCourses: 'courses/sorted',
        getCourseInstancesForClass: 'courseInstances/getCourseInstancesForClass'
      }),

      levelSessionsMapByUser () {
        return this.levelSessionsMapForClassroom(this.classroomState._id) || {}
      },

      classroomCreationDate () {
        return moment(parseInt(this.classroomState._id.substring(0, 8), 16) * 1000).format('MMMM Do, YYYY')
      },

      classroomStatsFromClassroom () {
        return {
          id: this.classroomState._id,
          name: this.classroomState.name,
          language: this.classroomState.aceConfig.language || 'python',
          numberOfStudents: this.classroomState.members.length || 0,
          classroomCreated: this.classroomCreationDate,
          archived: this.classroomState.archived
        }
      },

      // Maps the course Id to the levels associated.
      courseLevelsMap () {
        const map = new Map()
        const courseInstanceCourses = new Set()
        const courseInstances = this.getCourseInstancesForClass(this.classroomState.ownerID, this.classroomState._id)

        for (const { courseID, members } of courseInstances) {
          // We don't want to show course instances if there aren't any students assigned.
          if (!Array.isArray(members) || members.length === 0) {
            continue
          }
          courseInstanceCourses.add(courseID)
        }

        for (const course of this.classroomState.courses) {
          if (!courseInstanceCourses.has(course._id)) {
            continue
          }
          map.set(course._id, { levels: course.levels })
        }

        return map
      },
      /**
       * TODO: Migrate this to be a background stats calculation.
       * Returns an array of chapter stats objects with the following shape:
      {
        name: String
        assigned: Integer - number of members,
        progress: Float between 0 and 1.
      }
      */
      chapterStatsAdapter () {
        return this.sortedCourses
          .filter((course) => me.hasCampaignAccess(course))
          .map((course) => {
            // Splits off the "Chapter 1" part of the name
            // Expects the course name to have 'Chapter <int>:' structure.
            const splitName = course.name.split(':')
            let name = course.name
            if (splitName.length > 1) {
              name = splitName[0]
            }

            const result = {
              name,
              assigned: false,
              progress: 0
            }

            // If we have assigned this course then calculate the progress.
            if (this.courseLevelsMap.has(course._id)) {
              result.assigned = true
              const levels = this.courseLevelsMap.get(course._id).levels
              const levelSetInCourse = new Set(levels.map((l) => l.original))

              let progress = 0
              // Fallback to 1 to prevent division by 0 error in an empty class.
              const totalProgress = this.classroomState.members.length * levels.length || 1

              for (const memberId of this.classroomState.members) {
                for (const [levelOriginal, sessionData] of Object.entries(this.levelSessionsMapByUser[memberId] || [])) {
                  if (!levelSetInCourse.has(levelOriginal)) {
                    continue
                  }

                  if (sessionData.state.complete) {
                    progress += 1
                  }
                }
              }

              result.progress = progress / totalProgress
            }

            return result
          })
      }
    }
  }
</script>

<template>
  <ClassComponent
    :classroom-stats="classroomStatsFromClassroom"
    :chapter-stats="chapterStatsAdapter"
    @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
  />
</template>
