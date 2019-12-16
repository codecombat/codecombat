<script>
  import { courses } from 'core/api'
  import BaseModal from 'ozaria/site/components/common/BaseModal'

  export default Vue.extend({
    name: 'PartialUnitReleaseView',

    data: () => ({
      willUpdateCourse: null,
      loading: false,
      classrooms: [],
      courseId: null
    }),

    methods: {
      async onClickFetchClassrooms() {
        if (!this.courseId) {
          noty({
            text: 'Course ID needs to be set',
            type: 'error'
          })
          return
        }

        try {
          this.loading = true
          const classrooms = await courses.getAllClassroomLevels({ courseId: this.courseId })
          this.loading = false
          this.classrooms = classrooms[1] || [{ name: 'Nothing found' }]
        } catch (e) {
          noty({
            text: 'Could not fetch classroom levels: ' + e.message,
            type: 'error'
          })
        }
      },
      async onClickDryRun() {
        if (!this.courseId) {
          noty({
            text: 'Course ID needs to be set',
            type: 'error'
          })
          return
        }

        try {
          this.loading = true
          const classrooms = await courses.addLevelsForAllClassroomsDryRun({ courseId: this.courseId })
          this.classrooms = classrooms.wouldBeUpdated || [{ name: 'Nothing found' }]
        } catch (e) {
          noty({
            text: 'Could not perform dry run: ' + e.message,
            type: 'error'
          })
        }
        this.loading = false
      },
      onClickUpdateClassrooms() {
        if (!this.courseId) {
          noty({
            text: 'Course ID needs to be set',
            type: 'error'
          })
          return
        }

        this.willUpdateCourse = this.courseId
      },
      async reallyUpdateClassrooms() {
        const courseId = this.willUpdateCourse
        this.willUpdateCourse = null
        this.loading = true
        try {
          this.classrooms = await courses.addLevelsForAllClasses({ courseId })
        } catch (e) {
          noty({
            text: 'Could not perform add levels for classrooms: ' + e.message,
            type: 'error'
          })
        }
        this.loading = false
      },
      cancelUpdate() {
        this.willUpdateCourse = null
      }
    },

    components: {
      BaseModal
    }
  })
</script>

<template>
  <div class="partial-unit-release-view">
    <h1>Partial Unit Release</h1>
    <div v-if="!$store.getters['me/isAdmin']">
      You must be logged in as an admin to view this page.
    </div>
    <base-modal v-else-if="willUpdateCourse" class="confirmation-modal">
      <template #header>
        <span class="text-capitalize status-text"> Are you ready to update the classrooms? </span>
      </template>

      <template #body>
        <div>
          <p>The course id is: {{ willUpdateCourse }}</p>
        </div>
      </template>

      <template #footer>
        <button class="ozaria-button ozaria-secondary-button" v-on:click="cancelUpdate" data-dismiss="modal">Cancel</button>
        <button class="ozaria-button ozaria-primary-button" v-on:click="reallyUpdateClassrooms" data-dismiss="modal">Yes, let's do this!</button>
      </template>
    </base-modal>
    <div v-else>
      <label>
        <input type="text" class="form-control search-input" placeholder="Enter course id" v-model="courseId">
      </label>
      <h3>
        Find classrooms with the course id (harmless operation :)):
      </h3>
      <button @click="onClickFetchClassrooms" class="btn btn-primary">Search</button>
      <h3>
        Do a dry run to see how many classes would be added (harmless operation :))
      </h3>
      <button @click="onClickDryRun" class="btn btn-primary">Test</button>
      <h3>
        Update levels for all classrooms with this course id. <b>Warning: This will update the database!</b>
      </h3>
      <button @click="onClickUpdateClassrooms" class="btn btn-primary">Update all classrooms</button>

      <h4 v-if="loading">Loading...</h4>
      <div v-else class="classroom-list">
        <div v-for="classroom in classrooms" class="classroom-item">
          <p class="classroom-item-title">name: {{ classroom.name }}</p>
          <p>_id: {{ classroom._id }}</p>
          <p>codeCamel: {{ classroom.codeCamel }}</p>
          <p>ownerID: {{ classroom.ownerID }}</p>
          <!-- The full search shows levels, the dry run and update show changed level counts: -->
          <div v-if="classroom.matchingCourse">
            <p>Levels for the course in this classroom:</p>
            <div v-for="level in classroom.matchingCourse.levels">
              <p>name: {{ level.name }}</p>
              <p>url (slug): {{ level.slug }}</p>
              <p>original: {{ level.original }}</p>
            </div>
          </div>
          <p v-if="classroom.oldLevelCount">Total levels before: {{ classroom.oldLevelCount }}</p>
          <p v-if="classroom.newLevelCount">Total levels after: {{ classroom.newLevelCount }}</p>
          <div class="divider"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
  .partial-unit-release-view {
    color: white;
    padding: 5px;
  }

  .confirmation-modal {
    color: black;
  }

  .classroom-list {
    display: flex;
    flex-direction: column;
  }

  .classroom-item {
    display: flex;
    margin: 20px;
    flex-direction: column;
  }

  .search-input {
    width: 220px;
  }

  .will-modify-data {
    background-color: red;
  }

  .classroom-item-title {
    background-color: white;
    color: black;
    font-size: 20px;
    min-width: 100%;
  }

</style>
