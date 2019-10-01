<style scoped>
    li.classroom-list-row {
        display: flex;
        flex-direction: row;
        align-items: center;

        padding: 20px;
    }

    li.classroom-list-row:nth-child(2n) {
        background-color: #F5F5F5;
    }

    li.classroom-list-row:nth-child(2n + 1) {
        background-color: #EBEBEB;
    }

    li.classroom-list-row .class-information {
        width: 33%;
        margin-bottom: auto;
    }

    li.classroom-list-row .class-information h4 {
        font-weight: 600;
    }

    li.classroom-list-row .class-information .class-summary {
        flex-shrink: 0;

        font-size: 14px;
        height: 100%;
    }

    li.classroom-list-row .class-information .class-summary span {
        margin-right: 10px;
    }

    li.classroom-list-row .class-information .class-summary span:last-of-type {
        margin-right: 0;
    }

    ul.progress-dots {
        flex-grow: 1;

        display: flex;
        flex-wrap: wrap;
        flex-direction: row;
        justify-content: flex-end;

        padding-left: 20px;
        padding-right: 20px;

        list-style-type: none;
    }

    li.classroom-list-row .classroom-link {
        margin-left: auto;
        color: #999;

        line-height: normal;
        font-size: 35px;
    }

    li.classroom-list-row .classroom-link:hover {
        text-decoration: none;
    }
</style>

<template>
    <li class="classroom-list-row">
        <div class="class-information">
            <h4>{{ classroom.name }}</h4>
            <div class="class-summary">
                <span>
                    {{ $t('teacher.language') }}:
                    {{ capitalizedLanguage }}
                </span>

                <span>
                    {{ $t('courses.students') }}:
                    {{ classroom.members.length }}
                </span>
            </div>
        </div>

        <ul class="progress-dots">
            <progress-dot v-for="course in orderedCourses"
                          :key="course._id"
                          :classroom="classroom"
                          :course="course"
            ></progress-dot>
        </ul>

        <router-link
                class="classroom-link glyphicon glyphicon-chevron-right"
                :to="`/school-administrator/teacher/${classroom.ownerID}/classroom/${classroom._id}/`"
        ></router-link>
    </li>
</template>

<script>
  import { mapActions, mapState } from 'vuex'

  import { capitalLanguages, orderedCourseIDs } from 'core/utils'
  import CourseProgressDotView from './CourseProgressDotView'

  export default {
    created() {
      this.fetchLevelSessionsForClassroom(this.$props.classroom)
        .then(() => this.computeLevelCompletionsByUserForClassroom(this.$props.classroom._id))
    },

    components: {
      'progress-dot': CourseProgressDotView
    },

    props: {
      classroom: Object
    },

    computed: Object.assign({},
      mapState('courseInstances', {
        courseInstances: function (s) {
          return s.courseInstancesByTeacher[this.$props.classroom.ownerID]
        }
      }),

      {
        capitalizedLanguage: function () {
          const classroom = this.$props.classroom;

          if (classroom.aceConfig && classroom.aceConfig.language) {
            return capitalLanguages[classroom.aceConfig.language]
          }

          // TODO hitting this is a pretty big bug - current code handles this gracefully - should we or should we fail?
          return ''
        },

        orderedCourses: function () {
          const courses = this.$props.classroom.courses

          let orderedCourses = orderedCourseIDs
            .map(courseId => courses.find(course => course._id === courseId))
            .filter(c => typeof c !== 'undefined')

          return orderedCourses.filter(course =>
            this.courseInstances.find(ci => {
              return ci.courseID === course._id &&
                ci.classroomID === this.$props.classroom._id &&
                (ci.members || []).length > 0
            })
          )
        }
      }),

    methods: mapActions({
      fetchLevelSessionsForClassroom: 'levelSessions/fetchForClassroomMembers',
      computeLevelCompletionsByUserForClassroom: 'levelSessions/computeLevelCompletionsByUserForClassroom'
    }),
  }
</script>
