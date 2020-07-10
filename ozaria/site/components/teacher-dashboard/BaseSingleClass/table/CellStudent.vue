<script>
  import { mapMutations } from 'vuex'
  export default {
    props: {
      studentName: {
        type: String,
        required: true
      },
      studentId: {
        type: String,
        required: true
      },
      checked: {
        type: Boolean,
        required: true
      },
      isEnrolled: {
        type: Boolean,
        default: false
      }
    },

    methods: {
      ...mapMutations({
        openModalEditStudent: 'baseSingleClass/openModalEditStudent'
      })
    }
  }
</script>
<template>
  <div class="cell-student">
    <div class="student-checkbox">
      <input
        type="checkbox"
        :checked="checked"

        @change="$emit('change')"
      >
      <p
        @click="() => openModalEditStudent(studentId)"
      >
        {{ studentName }}
      </p>
    </div>
    <img
      v-if="isEnrolled"
      src="/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg"
    >
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .student-checkbox {
    display: flex;
    flex-direction: row;

    justify-content: center;
    align-items: center;

    p, input {
      margin: 0;
    }

    p {
      margin-left: 10px;
      cursor: pointer;
      text-decoration: underline;

      @include font-p-4-paragraph-smallest-gray;
      color: #476fb1;

      max-width: 125px;
      text-overflow: ellipsis;
      overflow-x: hidden;
    }
  }

  .cell-student {
    display: flex;
    flex-direction: row;

    justify-content: space-between;
    align-items: center;

    max-width: $studentNameWidth;
    width: $studentNameWidth;
    height: 29px;

    padding: 0 13px 0 20px;

    border-right: 1px solid #d8d8d8;
    border-bottom: 1px solid #d8d8d8;

    background-color: white;
    &:nth-child(even) {
      background-color: #f2f2f2;
    }
  }

</style>
