import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle", "overlay"]

  connect() {
    this.open = false
    this.updateAria()
  }

  toggle(event) {
    event.preventDefault()
    this.open ? this.close() : this.openMenu()
  }

  openMenu() {
    this.open = true
    this.show()
  }

  close(event) {
    if (event) event.preventDefault()
    this.open = false
    this.show()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.open) {
      this.close(event)
    }
  }

  show() {
    this.menuTarget.classList.toggle("hidden", !this.open)
    this.overlayTarget.classList.toggle("hidden", !this.open)
    this.toggleTarget.setAttribute("aria-expanded", this.open)
    document.body.classList.toggle("overflow-hidden", this.open)
  }

  updateAria() {
    this.toggleTarget.setAttribute("aria-expanded", this.open)
  }
}
