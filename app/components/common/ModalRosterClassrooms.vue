<template>
  <modal
    :title="$t('school_administrator.roster')"
    @close="$emit('close')"
  >
    <div class="roster">
      <p class="roster__text">
        Upload corresponding CSV for rostering
      </p>
      <div class="actions">
        <primary-button
          @click="() => roster('students')"
        >
          Sync Students
        </primary-button>

        <secondary-button
          @click="() => roster('teachers')"
        >
          Sync Teachers
        </secondary-button>
        <primary-button
          @click="() => roster('classes')"
        >
          Sync Classrooms
        </primary-button>
        <secondary-button
          @click="() => roster('classes-students')"
        >
          Sync Student & Classroom
        </secondary-button>
        <p class="info">
          {{ jobInfo }}
        </p>
        <p class="error">
          {{ errorMsg }}
        </p>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
import PrimaryButton from '../../../ozaria/site/components/teacher-dashboard/common/buttons/PrimaryButton.vue'
import SecondaryButton from '../../../ozaria/site/components/teacher-dashboard/common/buttons/SecondaryButton.vue'
import filesApi from 'app/core/api/files'
import backgroundJobApi from 'app/core/api/background-job'

require('core/services/filepicker')({
  accept: 'text/csv'
})

export default Vue.extend({
  name: 'ModalRosterClassrooms',
  components: {
    Modal,
    PrimaryButton,
    SecondaryButton
  },
  data () {
    return {
      jobInfo: '',
      errorMsg: ''
    }
  },
  methods: {
    async roster (type) {
      this.jobInfo = ''
      this.errorMsg = ''
      const jType = `roster-${type}`
      try {
        this.jobInfo = `Uploading csv for ${type}...`
        const { filename, metadata } = await this.uploadCsv()
        this.jobInfo = 'Uploaded'
        const job = await backgroundJobApi.create('naperville-roster', { filename, metadata, type: jType })
        this.jobInfo = `Syncing ${type} start....`
        await this.pollJob(job?.job)
        if (!this.errorMsg) {
          this.jobInfo = `Syncing ${type} completed, refresh the page to see the changes.`
        }
      } catch (err) {
        this.jobInfo = `Error syncing ${type}`
      }
    },
    uploadCsv () {
      return new Promise((resolve, reject) => {
        window.filepicker.pick({ mimetypes: ['text/csv'] }, async (InkBlob) => {
          const filename = `${Date.now()}-${InkBlob.filename}`
          const resp = await filesApi.saveFile({ ...InkBlob, path: 'naperville', force: 'true', filename })
          return resolve(resp)
        })
      })
    },
    async pollJob (jobId) {
      const sleep = async function (ms) {
        return new Promise(resolve => setTimeout(resolve, ms))
      }
      let poll = true
      this.errorMsg = ''
      while (poll) {
        const job = await backgroundJobApi.get(jobId)
        if (job.message) {
          this.jobInfo = job.message
        }
        if (job.status === 'failed') {
          this.jobInfo = ''
          this.errorMsg = job.message
          poll = false
        } else if (job.status === 'completed') {
          poll = false
        }
        console.log('jobInfo', this.jobInfo)
        await sleep(3000)
      }
    }
  }
})
</script>

<style lang="scss" scoped>
.roster {
  min-width: 300px;
  min-height: 200px;
}

.actions {
  display: flex;
  justify-content: space-evenly;
  align-items: center;
  flex-direction: column;

  button {
    padding: 8px 22px;
    margin-bottom: 15px;
  }
}

.error {
  color: red;
  font-weight: bold;
}
.info {
  font-weight: bold;
}
</style>
