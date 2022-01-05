<template>
  <modal
      title="Share Class"
      @close="$emit('close')"
      :backbone-dismiss-modal=true
      v-if="classroom"
  >
    <div class="share-class-modal">
      <div class="selected-class">{{classroom.name}}</div>
      <div class="small-text">{{$t('teacher_dashboard.share_info')}}</div>
      <form
          class="share-class-form"
          @submit.prevent="addTeacher"
      >
        <div class="form-group row">
          <div class="col-lg-6">
            <input class="form-control" id="share-teacher-email" type="text" v-model="email" placeholder="Teacher's email" required />
          </div>
          <div class="col-lg-4">
            <select class="select-dropdown form-control" @change="updatePermission" id="share-teacher-permission" required>
              <option value="" :selected="permission === ''" disabled>Permission</option>
              <option value="write" :selected="permission === 'write'">{{this.displayPermission('Write')}}</option>
              <option value="read" :selected="permission === 'read'">{{this.displayPermission('Read')}}</option>
            </select>
          </div>
          <div class="col-lg-2">
            <button type="submit" class="btn btn-primary" :disabled="addInProgress">
              Add
            </button>
          </div>
        </div>
        <div class="form-group error" v-if="error">
          {{error}}
        </div>
      </form>
      <div class="already-shared-with">
        <div class="already-shared-heading">Shared With:</div>
        <div v-if="this.alreadySharedWith">
          <ul>
            <li v-for="shared in alreadySharedWith" :key="shared.target">
              {{shared.email}} - {{displayPermission(shared.access)}} <icon-close @clicked="removeTeacher(shared)" /><span class="small-text" v-if="deleteInProgress === shared.target">deleting...</span>
            </li>
          </ul>
        </div>
        <div v-else class="small-text">
          {{$t('teacher_dashboard.shared_with_none')}}
        </div>
      </div>
      <div>
        Note:
        <ul>
          <li class="small-text">
            {{$t('teacher_dashboard.read_blurb')}}
          </li>
          <li class="small-text">
            {{$t('teacher_dashboard.write_blurb')}}
          </li>
        </ul>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from "app/components/common/Modal"
import usersApi from 'app/core/api/users'
import User from 'app/models/User'
import {mapActions, mapGetters} from 'vuex'
import classroomsApi from 'app/core/api/classrooms'
import IconClose from 'app/templates/icons/IconClose'
import { getDisplayPermission } from 'app/lib/classroom-utils'

export default Vue.extend({
  name: "ModalShareWithTeachers",
  components: {
    Modal,
    IconClose
  },
  props: {
    classroomId: {
      type: String
    }
  },
  data() {
    return {
      email: null,
      permission: 'write',
      error: null,
      deleteInProgress: null,
      addInProgress: false,
      alreadySharedWith: null
    }
  },
  async created() {
    await this.getClassroomForId(this.classroomId)
    await this.updateAlreadySharedWith()
  },
  computed: {
    ...mapGetters({
      getClassroomById: 'classrooms/classroomById'
    }),
    classroom () {
      console.log('cl', this.getClassroomById(this.classroomId))
      return this.getClassroomById(this.classroomId)
    }
  },
  watch: {
    addInProgress (val) {
      console.log('add', val)
      if (val === false) {
        this.updateAlreadySharedWith()
      }
    },
    deleteInProgress (val) {
      console.log('del', val)
      if (!val) {
        this.updateAlreadySharedWith()
      }
    }
  },
  methods: {
    ...mapActions({
      updateClassroom: 'classrooms/updateClassroom',
      addPermission: 'classrooms/addPermission',
      removePermission: 'classrooms/removePermission',
      getClassroomForId: 'classrooms/fetchClassroomForId'
    }),
    async addTeacher() {
      this.addInProgress = true
      this.error = ''
      let errMsg
      try {
        const user = await usersApi.getByEmail({ email: this.email }, { data: { includeRole: true } })

        const permissions = this.classroom.permissions || []
        const alreadyShared = permissions.find((perm) => perm.target === user._id)
        const owner = user._id === this.classroom.ownerID
        if (!User.isTeacher(user, true)) {
          errMsg = 'User does not have a teacher account'
        } else if (alreadyShared || owner) {
          errMsg = 'User already has permission'
        }
        this.error = errMsg
        if (errMsg) {
          this.addInProgress = false
          return
        }
        const newPermission = { target: user._id, access: this.permission }
        await this.addPermission({ classroom: this.classroom, permission: newPermission })
      } catch (err) {
        if (err.errorID === 'cant-fetch-nonteacher-by-email') {
          errMsg = 'User does not have a teacher account'
        } else {
          errMsg = err?.message
        }
        this.error = errMsg
      }
      this.addInProgress = false
    },
    updatePermission(e) {
      this.permission = e.target.value
    },
    async removeTeacher(permission) {
      this.deleteInProgress = permission.target
      await this.removePermission({ classroom: this.classroom, permission })
      this.deleteInProgress = null
    },
    displayPermission(permission) {
      return getDisplayPermission(permission)
    },
    async updateAlreadySharedWith() {
      console.log('updateAlrady', this.classroom.permissions)
      if (this.classroom.permissions.length) {
        const resp = await classroomsApi.getPermission({ classroomID: this.classroomId })
        this.alreadySharedWith = resp.data
        console.log('talre', this.alreadySharedWith)
      } else {
        this.alreadySharedWith = null
      }
    }
  }
})
</script>

<style scoped lang="scss">
.share-class-modal {
  width: 700px;
  padding: 10px;
}
.share-class-form {
  padding-top: 20px;
}
.select-dropdown {
  font-size: 14px;
  line-height: 20px;

  width: 100%;
}
.small-text {
  font-size: small;
  color: grey;
}
.error {
  color: red;
}
</style>
