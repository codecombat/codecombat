<template>
    <div></div>
</template>

<script>
  import TeacherClassView from 'app/views/courses/TeacherClassView'

  export default {
    created() {
      this.teacherClassView = new TeacherClassView({}, this.$route.params.classroomId)
    },

    mounted() {
      this.teacherClassView.render()
      this.$el.appendChild(this.teacherClassView.el)
    },

    render() {},

    beforeDestroy() {
      this.teacherClassView.destroy()
    }
  }
</script>
