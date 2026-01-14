import { Controller } from "@hotwired/stimulus"

// Controls progressive disclosure of type-specific form fields
// Shows/hides field sections based on selected resource type
export default class extends Controller {
  static targets = ["typeSelect", "typeFields"]

  connect() {
    // Show fields for pre-selected type on page load (e.g., when form has errors)
    this.showFieldsForType()
  }

  showFieldsForType() {
    const selectedType = this.typeSelectTarget.value

    // Hide all type-specific field sections
    this.typeFieldsTargets.forEach(section => {
      const sectionType = section.getAttribute("data-entry-type")

      if (sectionType === selectedType && selectedType !== "") {
        // Show matching section
        section.classList.remove("hidden")

        // Announce change to screen readers
        this.announceFieldVisibility(sectionType, true)

        // Set focus to first input in the revealed section for better UX
        this.focusFirstInput(section)
      } else {
        // Hide non-matching sections
        section.classList.add("hidden")
      }
    })
  }

  // Focus management: move focus to first input in newly revealed section
  focusFirstInput(section) {
    // Find first visible input, select, or textarea in the section
    const firstInput = section.querySelector('input:not([type="hidden"]), select, textarea')

    if (firstInput) {
      // Delay focus slightly to ensure section is fully visible
      setTimeout(() => {
        firstInput.focus()
      }, 100)
    }
  }

  // Announce section visibility changes to screen readers
  announceFieldVisibility(typeName, visible) {
    const action = visible ? "shown" : "hidden"
    const message = `${typeName} fields ${action}`

    // Create or update live region for screen reader announcement
    let liveRegion = document.getElementById("entry-form-announcements")

    if (!liveRegion) {
      liveRegion = document.createElement("div")
      liveRegion.id = "entry-form-announcements"
      liveRegion.setAttribute("role", "status")
      liveRegion.setAttribute("aria-live", "polite")
      liveRegion.setAttribute("aria-atomic", "true")
      liveRegion.className = "sr-only"
      document.body.appendChild(liveRegion)
    }

    liveRegion.textContent = message
  }
}
