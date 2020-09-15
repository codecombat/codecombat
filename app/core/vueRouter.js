import VueRouter from 'vue-router'

// new DSA
import BaseSchoolAdminDashboard from '../../ozaria/site/components/school-admin-dashboard/BaseSchoolAdminDashboard/index.vue'
import BaseMySchools from '../../ozaria/site/components/school-admin-dashboard/BaseMySchools/index.vue'
import BaseSchoolAdminLicenses from '../../ozaria/site/components/school-admin-dashboard/BaseSchoolAdminLicenses/index.vue'

import BaseAdministeredTeacherAllClasses from '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherAllClasses/index.vue'
import BaseAdministeredTeacherClassProgress from '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherClassProgress/index.vue'
import BaseAdministeredTeacherClassProjects from '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherClassProjects/index.vue'
import BaseAdministeredTeacherLicenses from '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherLicenses/index.vue'

import PageCinematicEditor from '../../ozaria/site/components/cinematic/PageCinematicEditor'
import BaseCinematicList from '../../ozaria/site/components/cinematic/PageCinematicEditor/BaseCinematicList'

import PageCutsceneEditorList from '../../ozaria/site/components/cutscene/PageCutsceneEditorList'
import PageCutsceneEditor from '../../ozaria/site/components/cutscene/PageCutsceneEditor'
import PageInteractiveEditor from '../../ozaria/site/components/interactive/PageInteractiveEditor'

import ArchivedElementsEditor from '../../ozaria/site/components/archived-elements/ArchivedElementsEditor'

import CinematicPlaceholder from '../../ozaria/site/components/cinematic/CinematicPlaceholder'

import BaseTeacherDashboard from '../../ozaria/site/components/teacher-dashboard/BaseTeacherDashboard/index.vue'
import BaseMyClasses from '../../ozaria/site/components/teacher-dashboard/BaseMyClasses/index.vue'
import BaseSingleClass from '../../ozaria/site/components/teacher-dashboard/BaseSingleClass/index.vue'
import BaseStudentProjects from '../../ozaria/site/components/teacher-dashboard/BaseStudentProjects/index.vue'
import BaseTeacherLicenses from '../../ozaria/site/components/teacher-dashboard/BaseTeacherLicenses/index.vue'
import BaseResourceHub from '../../ozaria/site/components/teacher-dashboard/BaseResourceHub/index.vue'
import PageEducatorSignup from '../../ozaria/site/components/sign-up/PageEducatorSignup/index.vue'

let vueRouter

export default function getVueRouter () {
  if (typeof vueRouter === 'undefined') {
    vueRouter = new VueRouter({
      // Routing is currently driven by Backbone Router.  When we migrate away from backbone, switch to history
      mode: 'abstract',

      routes: [
        {
          path: '/editor/cinematic',
          component: BaseCinematicList
        },
        {
          // TODO: The cinematic editor route should use vue guards to check for admin access.
          // TODO: Once we have a base editor component, use the nested route structure.
          path: '/editor/cinematic/:slug',
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
          path: '/editor/archived-elements',
          component: ArchivedElementsEditor,
          beforeEnter: (to, from, next) => {
            // TODO: Fix /editor redirect. The documentation says next('/editor') would redirect to /editor,
            // but it is not working as intended. Perhaps something to do with our use of Backbone and Vue together.
            // https://router.vuejs.org/guide/advanced/navigation-guards.html#per-route-guard
            next(me.isAdmin() ? true : '/editor')
          }
        },
        {
          path: '/school-administrator',
          component: BaseSchoolAdminDashboard,
          children: [
            { path: '', component: BaseMySchools },
            { path: 'teacher/:teacherId', component: BaseAdministeredTeacherAllClasses, props: true },
            { path: 'teacher/:teacherId/classes', component: BaseAdministeredTeacherAllClasses, props: true },
            { path: 'teacher/:teacherId/classes/:classroomId', component: BaseAdministeredTeacherClassProgress, props: true },
            { path: 'teacher/:teacherId/classes/:classroomId/projects', component: BaseAdministeredTeacherClassProjects, props: true },
            { path: 'teacher/:teacherId/licenses/', component: BaseAdministeredTeacherLicenses, props: true },
            { path: 'licenses', component: BaseSchoolAdminLicenses }
          ]
        },
        {
          path: '/teachers',
          component: BaseTeacherDashboard,
          children: [
            { path: '', component: BaseMyClasses },
            { path: 'classes', component: BaseMyClasses },
            { path: 'classes/:classroomId', component: BaseSingleClass, props: true },
            { path: 'projects/:classroomId', component: BaseStudentProjects, props: true },
            { path: 'licenses', component: BaseTeacherLicenses },
            { path: 'resources', component: BaseResourceHub }
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
        },
        {
          path: '/sign-up/educator',
          component: PageEducatorSignup
        }
      ]
    })
  }

  return vueRouter
}
