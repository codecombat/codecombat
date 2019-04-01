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
    }

    li.classroom-list-row .class-information .class-summary {
        font-size: 14px;
        height: 100%;

    }

    li.classroom-list-row .classroom-link {
        margin-left: auto;
        color: #999;

        line-height: normal;
    }

    li.classroom-list-row .classroom-link:hover {
        text-decoration: none;
    }
</style>

<template>
    <li class="classroom-list-row">
        <div class="class-information">
            <h5>{{ classroom.name }}</h5>
            <div class="class-summary">
                <span>
                    {{ $t('school_administrator.language') }}:
                    {{ capitalizedLanguage }}
                </span>

                <span>
                    {{ $t('school_administrator.students') }}:
                    {{ classroom.members.length }}
                </span>
            </div>
        </div>

        <router-link
                class="classroom-link glyphicon glyphicon-chevron-right"
                :to="`/teachers/classes/${classroom._id}`"
        ></router-link>
    </li>
</template>

<script>
    import { capitalLanguages } from 'core/utils'

    export default {
      created() {
        console.log(this)
      },

      props: {
        classroom: Object
      },

      computed: {
        capitalizedLanguage: function () {
          const classroom = this.$props.classroom;

          if (classroom.aceConfig && classroom.aceConfig.language) {
            return capitalLanguages[classroom.aceConfig.language]
          }

          // TODO this is a pretty big bug - current code handles this gracefully - should we or should we fail?
          return ''
        }
      }
    }
</script>
