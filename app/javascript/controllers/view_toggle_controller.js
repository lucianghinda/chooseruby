import { Controller } from "@hotwired/stimulus"

// Toggles between grid and list layouts, persisting preference in localStorage.
export default class extends Controller {
  static targets = ["container", "button"]
  static values = {
    key: String,
    defaultView: { type: String, default: "grid" },
    gridClass: String,
    listClass: String,
  }

  connect() {
    this.currentView = this.loadPreference() || this.defaultViewValue
    this.applyView()
  }

  switch(event) {
    const view = event.currentTarget.dataset.view
    if (!view) return
    this.currentView = view
    this.applyView()
    this.savePreference(view)
  }

  applyView() {
    const gridClasses = this.gridClassValue.split(" ")
    const listClasses = this.listClassValue.split(" ")

    this.containerTarget.classList.remove(...gridClasses, ...listClasses)
    if (this.currentView === "list") {
      this.containerTarget.classList.add(...listClasses)
      this.containerTarget.dataset.viewMode = "list"
    } else {
      this.containerTarget.classList.add(...gridClasses)
      this.containerTarget.dataset.viewMode = "grid"
    }

    this.buttonTargets.forEach((button) => {
      const isActive = button.dataset.view === this.currentView
      button.classList.toggle("bg-slate-900", isActive)
      button.classList.toggle("text-white", isActive)
      button.classList.toggle("shadow-sm", isActive)
      button.classList.toggle("bg-slate-100", !isActive)
      button.classList.toggle("text-slate-600", !isActive)
    })
  }

  loadPreference() {
    try {
      return localStorage.getItem(this.preferenceKey())
    } catch (error) {
      return null
    }
  }

  savePreference(view) {
    try {
      localStorage.setItem(this.preferenceKey(), view)
    } catch (error) {
      // Ignore storage failures
    }
  }

  preferenceKey() {
    return this.keyValue || "chooseruby_view"
  }
}
