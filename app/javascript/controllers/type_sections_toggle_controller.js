import { Controller } from "@hotwired/stimulus"

// Progressive disclosure for the homepage type sections. Shows a limited set by
// default and expands to reveal all, remembering the user's choice.
export default class extends Controller {
  static targets = ["section", "toggle", "label", "icon"]
  static values = {
    initialCount: { type: Number, default: 4 },
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.storageKey = "chooseruby_type_sections_expanded"
    const stored = window.localStorage.getItem(this.storageKey)
    if (stored === "true") this.expandedValue = true
    this.applyState()
    this.updateButton()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    window.localStorage.setItem(this.storageKey, this.expandedValue)
    this.applyState()
    this.updateButton()
    if (this.expandedValue) this.scrollAfterExpand()
  }

  applyState() {
    const visibleCount = this.initialCountValue || 0
    this.sectionTargets.forEach((section, index) => {
      const shouldShow = this.expandedValue || index < visibleCount
      section.classList.toggle("hidden", !shouldShow)
      section.setAttribute("aria-hidden", (!shouldShow).toString())
    })
  }

  updateButton() {
    const remaining = Math.max(this.sectionTargets.length - this.initialCountValue, 0)
    const hasMoreThanInitial = remaining > 0

    this.toggleTarget.classList.toggle("hidden", !hasMoreThanInitial)
    if (!hasMoreThanInitial) return

    this.toggleTarget.setAttribute("aria-expanded", this.expandedValue.toString())
    this.labelTarget.textContent = this.expandedValue ? "Show fewer types" : `Show ${remaining} more types`
    this.iconTarget.classList.toggle("rotate-180", this.expandedValue)
  }

  scrollAfterExpand() {
    window.requestAnimationFrame(() => {
      this.toggleTarget.scrollIntoView({ behavior: "smooth", block: "center" })
    })
  }
}
