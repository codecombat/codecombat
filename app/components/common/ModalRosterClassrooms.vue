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
          @click="rosterStudents"
        >
          Sync Students
        </primary-button>

        <secondary-button>
          Sync Teachers
        </secondary-button>
        <primary-button>
          Sync Classrooms
        </primary-button>
        <secondary-button>
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
    async rosterStudents () {
      this.jobInfo = ''
      try {
        this.jobInfo = 'Uploading csv...'
        const { filename, metadata } = await this.uploadCsv()
        this.jobInfo = 'Uploaded'
        const job = await backgroundJobApi.create('naperville-roster', { filename, metadata, type: 'roster-students' })
        this.jobInfo = 'Syncing students start....'
        await this.pollJob(job?.job)
        this.jobInfo = 'Syncing students completed'
      } catch (err) {
        this.jobInfo = 'Error syncing students'
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
      while (poll) {
        const job = await backgroundJobApi.get(jobId)
        if (job.status === 'failed') {
          this.errorMsg = job.error
          poll = false
        }
        if (job.status === 'completed') {
          poll = false
        }
        if (job.message) {
          this.jobInfo = job.message
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
}
.info {
  font-weight: bold;
}
</style>
