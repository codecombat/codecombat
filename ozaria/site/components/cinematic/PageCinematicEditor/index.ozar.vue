<script>
  import { getCinematic, putCinematic } from '../../../api/cinematic'
  import BaseModal from 'ozaria/site/components/common/BaseModal'
  import Cinematic from '../../../models/Cinematic'
  import CinematicCanvas from '../common/CinematicCanvas'
  import CocoCollection from 'app/collections/CocoCollection'
  import LayoutCenterContent from '../../common/LayoutCenterContent'
  import { QUILL_CONFIG } from 'ozaria/engine/cinematic/constants'
  import { QuillDeltaToHtmlConverter } from 'quill-delta-to-html'
  const FlexSearch = require('flexsearch')
  const api = require('core/api')
  const Quill = require('quill')
  require('core/services/filepicker')()

  require('lib/setupTreema')

  module.exports = Vue.extend({
    components: {
      BaseModal,
      'cinematic-canvas': CinematicCanvas,
      'layout-center-content': LayoutCenterContent
    },

    props: {
      slug: {
        type: String,
        required: true
      }
    },

    data: () => ({
      cinematic: null,
      treema: null,
      rawData: null,
      state: {
        saving: false
      },
      rerenderKey: 0,
      programmingLanguage: 'python',
      dialogSearch: null,
      dialogSearchInput: '',
      dialogSearchResults: [],
      showRichEdit: false
    }),

    computed: {
      heading () {
        if (!this.cinematic) {
          return `No Cinematic Loaded`
        }
        return `Cinematic Editor: '${this.cinematic.get('name')}'`
      }
    },
    watch: {
      dialogSearchInput (val) {
        if (!this.dialogSearch) {
          return
        }
        this.debouncedSearchDialogText()
      }
    },
    mounted () {
      if (!me.hasCinematicEditorAccess()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/editor', { trigger: true })
      }

      this.debouncedSearchDialogText = _.debounce(this.searchDialogText, 250)
      this.debouncedRebuildSearch = _.debounce(this.constructNewDialogueSearch, 250)

      this.fetchCinematic(this.slug)
    },
    methods: {
      /**
       * Fetch and populate treema with cinematic slug.
       */
      async fetchCinematic (slug) {
        try {
          this.cinematic = new Cinematic(await getCinematic(slug))
        } catch (e) {
          return noty({
            text: `Error finding slug '${slug}'.`,
            type: 'error',
            timeout: 3000,
            callback: {
              onClose: () => {
                application.router.navigate('/editor/cinematic', { trigger: true })
              }
            }
          })
        }

        const data = $.extend(true, {}, this.cinematic.attributes)
        const el = $(`<div></div>`)
        const files = new CocoCollection(await api.files.getDirectory({ path: 'cinematic' }), { model: Cinematic })
        const treema = this.treema = TreemaNode.make(el, {
          data: data,
          schema: Cinematic.schema,
          // Automatically uploads the file to /file/cinematic/<fileName>
          // You can view files at /admin/files
          filePath: 'cinematic',
          files,
          callbacks: {
            change: this.pushChanges,
            jsonToHtml: this.quillJsonToHtml,
            showRichTextModal: this.showRichTextModal
          }
        })
        treema.build()
        $(this.$refs.treemaEditor).append(el)

        this.debouncedRebuildSearch()
      },

      /**
       * Pushes changes from treema to the cinematic model.
       */
      pushChanges () {
        this.cinematic.set(_.cloneDeep(this.treema.data))
        this.debouncedRebuildSearch()
      },

      constructNewDialogueSearch () {
        if (!this.dialogSearch) {
          this.dialogSearch = new FlexSearch()
        }

        this.dialogSearch.destroy().init({
          tokenize: 'strict',
          depth: 3,
          doc: {
            id: 'id',
            field: 'text'
          }
        })

        const cinematicText = Cinematic.flattenDialogueText(this.cinematic)
        this.dialogSearch.add(cinematicText)
      },

      /**
       * Ensures that there is an empty `i18n` field set on the cinematic.
       * Allows fields to be translated via /i18n route.
       */
      makeTranslatable () {
        if (!(this.treema || {}).data) {
          noty({ text: 'Nothing to translate', timeout: 1000 })
          return
        }

        if (!window.confirm('This will populate any missing i18n fields so that cinematics can be translated. Do you want to continue?')) {
          noty({ text: 'Cancelled', timeout: 1000 })
          return
        }

        const cinematicData = this.treema.data

        const i18n = cinematicData.i18n
        if (i18n === undefined) {
          cinematicData.i18n = { '-': { '-': '-' } }
        }

        const shots = cinematicData.shots || []
        for (const shot of shots) {
          const dialogNodes = shot.dialogNodes || []
          for (const dialogNode of dialogNodes) {
            const i18n = dialogNode.i18n
            if ((!i18n) && dialogNode.text) {
              dialogNode.i18n = { '-': { '-': '-' } }
            }
          }
        }

        noty({ text: 'Translations added. Please save to keep changes', type: 'success', timeout: 8000 })
        this.pushChanges()
      },

      /**
       * Saves the cinematic to the database.
       * Only the shots property will be saved.
       */
      async saveCinematic () {
        this.state.saving = true
        try {
          await putCinematic({ data: this.cinematic.toJSON() })
          noty({ text: 'Saved', type: 'success', timeout: 1000 })
        } catch (e) {
          noty({ text: e.message, type: 'error', timeout: 1000 })
        }
        this.state.saving = false
      },

      /**
       * Runs the cinematic on the right hand side of the editor.
       */
      runCinematic () {
        this.rerenderKey += 1
        this.rawData = this.rawData || {}
        this.rawData = JSON.parse(JSON.stringify(this.treema.data))
      },

      navigateToList () {
        window.application.router.navigate(`/editor/cinematic/`, { trigger: true })
      },

      searchDialogText () {
        if ((this.dialogSearchInput || '').length > 0) {
          this.dialogSearch.search(this.dialogSearchInput, results => {
            this.dialogSearchResults = results
          })
        }
      },

      /**
       * Opens all dialogue nodes that match the text.
       */
      openDialogueNodes (text) {
        this.treema.childrenTreemas.shots.close()
        const nodesToOpen = Cinematic.findDialogTextPath(this.cinematic, text)
        for (const [shotIdx, dialogIdx] of nodesToOpen) {
          const shots = this.treema.childrenTreemas.shots

          // Path is based on the cinematic schema for accessing dialogue nodes.
          shots.open()
          shots.childrenTreemas[shotIdx].open()
          shots.childrenTreemas[shotIdx].childrenTreemas.dialogNodes.open()
          shots.childrenTreemas[shotIdx].childrenTreemas.dialogNodes.childrenTreemas[dialogIdx].open()
        }
      },

      /**
       * Show rich text editor modal with 3rd party Quill editor
       */
      showRichTextModal (data, saveChangesCallback) {
        this.showRichEdit = true
        // Rich text modal has to be showing before this works
        setTimeout(() => {
          const ozariaChalkboardFontColors = ['#0C725A', '#4425D9', '#BA0ABA', '#CD0638', '#0F6CD1', '#94653C']
          this.quill = new Quill('#rich-editor', {
            modules: {
              toolbar: [
                [{ 'font': [] }],
                // TODO: make font size dropdown show actual sizes we want instead of built-in values
                // [{ 'size': [false, '18px', '22px', '24px', '26px', '28px', '30px', '32px'] }],
                [{ 'size': [ 'small', false, 'large', 'huge' ] }],
                ['bold', 'italic', 'underline', 'strike'],
                [{ 'color': ozariaChalkboardFontColors }, { 'background': ozariaChalkboardFontColors }],
                ['image'],
                [{ align: [false, 'center', 'right'] }],
                ['clean']
              ]
            },
            theme: 'snow'
          })
          const toolbar = this.quill.getModule('toolbar')
          toolbar.addHandler('image', this.uploadAndInsertImageCallback)
          this.quill.setContents(data)
          this.updateLocalRichEditCallback = saveChangesCallback
        }, 100)
      },

      /**
       * Upload an image and insert via URL into Quill editor
       * TODO: consolidate file picker and upload code copied from treema-ext.coffee
       */
      uploadAndInsertImageCallback () {
        filepicker.pick((InkBlob) => {
          const body = {
            url: InkBlob.url,
            filename: InkBlob.filename,
            mimetype: InkBlob.mimetype,
            path: 'cinematic',
            force: true
          }

          const uploadingPath = ['cinematic', InkBlob.filename].join('/')

          const imageUploadedCallback = (url) => {
            this.quill.insertEmbed(this.quill.getSelection().index, 'image', url)
          }
          if (window.application.isProduction()) {
            $.ajax('/file', { type: 'POST', data: body, success: () => imageUploadedCallback(`/file/${uploadingPath}`) })
          } else {
            setTimeout(() => imageUploadedCallback('https://www.ozaria.com/images/pages/not_found/404_1.png'), 500)
          }
        })
      },

      updateLocalRichEdit () {
        if (this.updateLocalRichEditCallback) {
          this.updateLocalRichEditCallback(JSON.parse(JSON.stringify(this.quill.getContents())))
        }
        this.closeRichEdit()
      },

      closeRichEdit () {
        this.showRichEdit = false
      },

      quillJsonToHtml (quillJson) {
        return new QuillDeltaToHtmlConverter(quillJson.ops, QUILL_CONFIG).convert()
      }
    }
  })
</script>

<template>
  <div
    v-if="cinematic"
    class="container"
  >
    <!-- Have a cinematic Slug -->
    <div class="row">
      <div class="col-md-8">
        <h1>{{ heading }}</h1>
      </div>
      <div class="col-md-4">
        <span>There is no autosave.</span>
        <button
          :disabled="state.saving || !cinematic"
          @click="saveCinematic"
        >
          save
        </button>
        <button @click="runCinematic">
          Test Cinematic
        </button>
        <button><a @click="navigateToList">Back to list view</a></button>
        <button @click="makeTranslatable">
          Make Translatable
        </button>
      </div>
    </div>

    <div class="row">
      <div class="col-md-6">
        <label>User Language:</label><select v-model="programmingLanguage">
          <option>python</option>
          <option>javascript</option>
        </select>
        <div
          v-once
          id="treema-editor"
          ref="treemaEditor"
        />
      </div>
      <div class="col-md-6">
        <div class="dialogue-search-tool">
          <label>Search Dialogue: </label>
          <input
            v-model="dialogSearchInput"
            placeholder="Search dialog text"
          >
          <ul>
            <li
              v-for="{ id, text } in dialogSearchResults"
              :key="id"
              @click="() => openDialogueNodes(text)"
            >
              {{ `${text}` }}
            </li>
          </ul>
        </div>
      </div>
      <div class="row">
        <layout-center-content v-if="rawData">
          <cinematic-canvas
            :key="rerenderKey"
            :cinematic-data="rawData"
            :user-options="{ programmingLanguage }"
          />
        </layout-center-content>
      </div>
    </div>
    <base-modal
      v-if="showRichEdit"
      style="min-width:50%"
    >
      <template #header>
        <span class="text-capitalize status-text">Update Chalkboard Content</span>
      </template>

      <template #body>
        <div class="rich-editor-container">
          <div id="rich-editor" />
        </div>
      </template>

      <template #footer>
        <button @click="updateLocalRichEdit">
          Update
        </button>
        <button @click="closeRichEdit">
          Cancel
        </button>
      </template>
    </base-modal>
  </div>
</template>

<style scoped>
  @import 'https://cdn.quilljs.com/1.3.6/quill.snow.css';

  .container {
    margin-top: 30px;
    background-color: white;
    padding: 20px;
    width: 98%;
  }

  button {
    margin: 5px;
    padding: 5px;
  }

  .headings {
    border-bottom: 2px solid #dddddd;
    margin-bottom: 20px
  }

  .dialogue-search-tool {
    margin-top: 32px;
    border: 1px solid #7A7A7A;
    padding: 10px;
  }

  .dialogue-search-tool > ul {
    height: 200px;
    overflow: scroll;
    list-style: none;
    padding: 20px 10px;
  }

  .dialogue-search-tool ul li {
    cursor: pointer;
  }

  .dialogue-search-tool ul li:hover {
    background-color: #cccccc;
  }

  .rich-editor-container {
    width: 100%;
    min-height: 40px
  }

</style>
