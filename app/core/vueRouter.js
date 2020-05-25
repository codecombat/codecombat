import VueRouter from 'vue-router'

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
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cinematic/PageCinematicEditor'),
          props: true
        },
        {
          path: '/editor/cutscene',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cutscene/PageCutsceneEditorList')
        },
        {
          path: '/editor/cutscene/:slugOrId',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cutscene/PageCutsceneEditor'),
          props: true
        },
        {
          path: '/editor/interactive/:slug?',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/interactive/PageInteractiveEditor'),
          props: true
        },
        {
          path: '/school-administrator',
          component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/SchoolAdministratorComponent'),
          children: [
            { path: '', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/teachers/SchoolAdminTeacherListView') },
            { path: 'teacher/:teacherId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/dashboard/SchoolAdminDashboardTeacherView') },
            { path: 'teacher/:teacherId/classroom/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/courses/TeacherClassView.vue') },
            { path: 'teacher/:teacherId/classroom/:classroomId/:studentId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/teachers/classes/TeacherStudentView.vue') }
          ]
        },
        {
          path: '/cinematicplaceholder/:levelSlug?',
          component: () => import(/* webpackChunkName: "play" */ '../../ozaria/site/components/cinematic/CinematicPlaceholder'),
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
