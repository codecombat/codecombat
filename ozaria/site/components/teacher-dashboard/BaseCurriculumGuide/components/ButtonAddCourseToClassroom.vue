<script>
import { mapActions } from 'vuex'

export default {
  props: {
    course: {
      type: Object,
      required: true
    },
    classroom: {
      type: Object,
      required: true
    },
  },

  data () {
    return {
      isAddingCourse: false,
      hasAddedCourse: false,
    }
  },

  methods: {
    ...mapActions({
      addCourseToClassroom: 'classrooms/addOrUpdateCourse',
    }),

    async onClick (e) {
      this.$emit('click')
      this.isAddingCourse = true
      await this.addCourseToClassroom({
        classroomId: this.classroom._id,
        courseId: this.course._id,
      })
      this.isAddingCourse = false
      this.hasAddedCourse = true
    }
  },
}
</script>

<template>
  <button
    v-if="!hasAddedCourse"
    :class="isAddingCourse ? 'locked' : null"
    :disabled="isAddingCourse"
    @click="onClick"
  >
    <div
      id="AddCourseToClassroom"
    />
    <span v-if="!isAddingCourse">{{ $t('teacher_dashboard.add_course_to_classroom') }}</span>
    <span v-else>{{ $t('common.loading') }}</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#AddCourseToClassroom {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconAddStudents.svg);
  height: 23px;
  width: 19px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;
  margin-right: 7px;
}

.locked #AddCourseToClassroom {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconAddStudents_Gray.svg);
}

button {
  background-color: $twilight;
  border-radius: 4px;
  border-width: 0;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  color: $moon;
  font-size: 14px;
  line-height: 16px;
  font-weight: 600;
  background-image: unset;

  &:hover {
    background-color: #355ea0;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  padding: 0 15px;
  justify-content: center;
  align-items: center;

  &.locked {
    background: #adadad;
    cursor: default;
    color: $pitch;
  }
}
</style>
