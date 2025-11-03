import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PageHeader',
  props: {
    title: {
      type: String,
      required: true
    },
    description: {
      type: String,
      default: ''
    },
    breadcrumbs: {
      type: Array as () => Array<{ title: string, path?: string }>,
      default: () => []
    }
  },
  setup(props) {
    return () => (
      <div class="page-header">
        <div class="breadcrumbs">
          {props.breadcrumbs.map((item, index) => (
            <span key={index}>
              {item.path ? (
                <router-link to={item.path}>{item.title}</router-link>
              ) : (
                <span>{item.title}</span>
              )}
              {index < props.breadcrumbs.length - 1 && <span class="separator">/</span>}
            </span>
          ))}
        </div>
        <h1 class="title">{props.title}</h1>
        {props.description && <div class="description">{props.description}</div>}
      </div>
    )
  }
})