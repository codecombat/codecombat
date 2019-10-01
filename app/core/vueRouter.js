import VueRouter from 'vue-router'

import SchoolAdminDashboard from 'app/views/school-administrator/SchoolAdministratorComponent'
import SchoolAdminDashboardTeacherListView from 'app/views/school-administrator/teachers/SchoolAdminTeacherListView'
import SchoolAdminTeacherView from 'app/views/school-administrator/dashboard/SchoolAdminDashboardTeacherView'

import TeacherClassView from 'app/views/courses/TeacherClassView.vue'
import TeacherStudentView from 'app/views/teachers/classes/TeacherStudentView.vue'

import PageCinematicEditor from '../../ozaria/site/components/cinematic/PageCinematicEditor'
import PageCutsceneEditorList from '../../ozaria/site/components/cutscene/PageCutsceneEditorList'
import PageCutsceneEditor from '../../ozaria/site/components/cutscene/PageCutsceneEditor'
import PageInteractiveEditor from '../../ozaria/site/components/interactive/PageInteractiveEditor'

import CinematicPlaceholder from '../../ozaria/site/components/cinematic/CinematicPlaceholder'

let vueRouter

export default function getVueRouter () {
  if (typeof vueRouter === 'undefined') {
    vueRouter = new VueRouter({
      // Routing is currently driven by Backbone Router.  When we migrate away from backbone, switch to history
      mode: 'abstract',

      routes: [
        {
          // TODO: The cinematic editor route should use vue guards to check for admin access.
          // TODO: Once we have a base editor component, use the nested route structure.
          path: '/editor/cinematic/:slug?',
          component: PageCinematicEditor,
          props: true
        },
        {
          path: '/editor/cutscene',
          component: PageCutsceneEditorList
        },
        {
          path: '/editor/cutscene/:slugOrId',
          component: PageCutsceneEditor,
          props: true
        },
        {
          path: '/editor/interactive/:slug?',
          component: PageInteractiveEditor,
          props: true
        },
        {
          path: '/school-administrator',
          component: SchoolAdminDashboard,
          children: [
            { path: '', component: SchoolAdminDashboardTeacherListView },
            { path: 'teacher/:teacherId', component: SchoolAdminTeacherView },
            { path: 'teacher/:teacherId/classroom/:classroomId', component: TeacherClassView },
            { path: 'teacher/:teacherId/classroom/:classroomId/:studentId', component: TeacherStudentView }
          ]
        },
        {
          path: '/cinematicplaceholder/:levelSlug?',
          component: CinematicPlaceholder,
          props: (route) => {
            return {
              levelSlug: route.params.levelSlug
            }
          }
        }
      ]
    })
  }

  return vueRouter
}
