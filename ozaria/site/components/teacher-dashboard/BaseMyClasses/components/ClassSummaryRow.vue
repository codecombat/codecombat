<script>
  import ClassInfoRow from '../../common/ClassInfoRow'
  import IconEllipsis from '../../common/icons/IconEllipsis'
  export default {
    components: {
      ClassInfoRow,
      IconEllipsis
    },
    props: {
      classroomName: {
        type: String,
        required: true
      },
      language: {
        type: String,
        required: true
      },
      numStudents: {
        type: Number,
        required: true
      },
      dateCreated: {
        type: String,
        required: true
      }
    }
  }
</script>

<template>
  <div id="class-summary-row">
    <div
      id="class-header"
      class="flex-row"
    >
      <div class="flex-row">
        <h2>{{ classroomName }}</h2>
        <class-info-row
          :language="language"
          :num-students="numStudents"
          :date-created="dateCreated"
        />
      </div>
      <div
        class="btn-ellipse"
        @click="$emit('clickTeacherArchiveModalButton')"
      >
        <icon-ellipsis />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  h2 {
    @include font-h-4-nav-uppercase-black;
    padding-right: 24px;
  }

  #class-summary-row {
    background-color: white;
  }

  #class-header {
    border: 0.5px solid #d8d8d8;
    height: 46px;

    box-shadow: 0px 4px 4px rgba(0,0,0,0.06);
    padding-left: 30px;

    justify-content: space-between;
  }

  .flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .btn-ellipse {
    border: 0.5px solid #d8d8d8;
    width: 62px;
    height: 46px;

    display: flex;
    justify-content: center;
    align-items: center;

    cursor: pointer;

    box-shadow: 0px 4px 4px rgba(0,0,0,0.11);

    &:hover {
      box-shadow: inset 0px 3px 10px rgba(0,0,0,0.1);
    }
  }
</style>
