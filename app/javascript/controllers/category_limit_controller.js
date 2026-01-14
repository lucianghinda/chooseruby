import { Controller } from "@hotwired/stimulus"

// Limits category selection to a maximum of 3 checkboxes
export default class extends Controller {
  static targets = ["checkbox"]
  static values = { limit: { type: Number, default: 3 } }

  checkLimit() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount >= this.limitValue) {
      // Disable unchecked boxes when limit is reached
      this.checkboxTargets.forEach(checkbox => {
        if (!checkbox.checked) {
          checkbox.disabled = true
        }
      })
    } else {
      // Re-enable all checkboxes when below limit
      this.checkboxTargets.forEach(checkbox => {
        checkbox.disabled = false
      })
    }
  }
}
