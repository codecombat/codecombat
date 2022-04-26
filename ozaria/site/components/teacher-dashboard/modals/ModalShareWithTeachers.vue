<template>
  <modal
    title="Share Class"
    @close="$emit('close')"
  >
    <div class="share-class-modal">
      <div class="selected-class">{{classroom.name}}</div>
      <div class="small-text">{{this.$t('teacher_dashboard.share_info')}}</div>
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
        <div v-if="this.classroom.permissions.length > 0">
          <ul>
            <li v-for="shared in this.getAlreadySharedWith" :key="shared.target">
              {{shared.email}} - {{displayPermission(shared.access)}} <icon-close @clicked="removeTeacher(shared)" /><span class="small-text" v-if="deleteInProgress === shared.target">deleting...</span>
            </li>
          </ul>
        </div>
        <div v-else class="small-text">
          {{this.$t('teacher_dashboard.shared_with_none')}}
        </div>
      </div>
      <div>
        Note:
        <ul>
          <li class="small-text">
            {{this.$t('teacher_dashboard.read_blurb')}}
          </li>
          <li class="small-text">
            {{this.$t('teacher_dashboard.write_blurb')}}
          </li>
        </ul>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from "../../common/Modal"
import usersApi from '../../../../../app/core/api/users'
import User from 'app/models/User'
import { mapActions } from 'vuex'
import classroomsApi from '../../../../../app/core/api/classrooms'
import IconClose from '../../teacher-dashboard/common/icons/IconClose'
import { getDisplayPermission } from '../../../common/utils'

export default {
  name: "ModalShareWithTeachers",
  components: {
    Modal,
    IconClose,
  },
  props: {
    classroom: {
      type: Object,
      required: true,
    }
  },
  data() {
    return {
      email: null,
      permission: 'write',
      error: null,
      deleteInProgress: null,
      addInProgress: false,
    }
  },
  asyncComputed: {
    getAlreadySharedWith() {
      if (this.classroom.permissions.length) {
        return classroomsApi.getPermission({ classroomID: this.classroom._id })
          .then((resp) => {
            return resp.data
          })
      }
      return null
    }
  },
  methods: {
    ...mapActions({
      updateClassroom: 'classrooms/updateClassroom',
      addPermission: 'classrooms/addPermission',
      removePermission: 'classrooms/removePermission',
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
    }
  }
}
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
