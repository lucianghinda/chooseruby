import { Controller } from "@hotwired/stimulus"

// Generates proof-of-work hashcash token before form submission
// Provides spam protection by requiring client-side computation
export default class extends Controller {
  static targets = ["token", "submitButton"]

  connect() {
    this.isGenerating = false
    this.tokenGenerated = false
  }

  async generateToken(event) {
    // If token already generated, allow submission
    if (this.tokenGenerated) {
      return
    }

    // Prevent form submission until token is generated
    event.preventDefault()

    // Prevent multiple simultaneous generation attempts
    if (this.isGenerating) {
      return
    }

    this.isGenerating = true
    this.showLoadingState()

    try {
      // Generate hashcash token
      const token = await this.computeHashcash()

      // Set token value in hidden field
      if (this.hasTokenTarget) {
        this.tokenTarget.value = token
        this.tokenGenerated = true
      }

      // Submit the form programmatically
      this.hideLoadingState()
      this.element.submit()
    } catch (error) {
      console.error("Hashcash generation failed:", error)
      this.showError()
      this.hideLoadingState()
      this.isGenerating = false
    }
  }

  // Compute hashcash proof-of-work token
  // This is a simplified implementation - in production, use the active_hashcash JS library
  async computeHashcash() {
    // Get the resource path for hashcash
    const resource = window.location.pathname

    // Difficulty level should match server configuration (14 bits)
    const bits = 14
    const timestamp = Math.floor(Date.now() / 1000)

    // Generate hashcash stamp
    // Format: version:bits:timestamp:resource::counter
    let counter = 0
    let stamp = ""

    // Find a stamp that produces a hash with required leading zero bits
    while (true) {
      stamp = `1:${bits}:${timestamp}:${resource}::${counter}`
      const hash = await this.sha1(stamp)

      if (this.hasRequiredZeroBits(hash, bits)) {
        break
      }

      counter++

      // Yield to browser every 1000 iterations to prevent UI freeze
      if (counter % 1000 === 0) {
        await this.sleep(0)
      }
    }

    return stamp
  }

  // Compute SHA-1 hash using Web Crypto API
  async sha1(message) {
    const msgBuffer = new TextEncoder().encode(message)
    const hashBuffer = await crypto.subtle.digest("SHA-1", msgBuffer)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("")
    return hashHex
  }

  // Check if hash has required number of leading zero bits
  hasRequiredZeroBits(hashHex, bits) {
    const requiredZeroBytes = Math.floor(bits / 8)
    const remainingBits = bits % 8

    // Check full zero bytes
    for (let i = 0; i < requiredZeroBytes; i++) {
      if (hashHex.substr(i * 2, 2) !== "00") {
        return false
      }
    }

    // Check remaining bits if any
    if (remainingBits > 0) {
      const nextByte = parseInt(hashHex.substr(requiredZeroBytes * 2, 2), 16)
      const mask = 0xFF << (8 - remainingBits)
      if ((nextByte & mask) !== 0) {
        return false
      }
    }

    return true
  }

  // Utility to yield to browser event loop
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Show loading state during token generation
  showLoadingState() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("opacity-50", "cursor-not-allowed")

      // Store original text and show loading message
      this.originalButtonText = this.submitButtonTarget.textContent
      this.submitButtonTarget.textContent = "Verifying submission..."
    }

    // Show loading indicator
    this.createLoadingIndicator()
  }

  hideLoadingState() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")

      // Restore original button text
      if (this.originalButtonText) {
        this.submitButtonTarget.textContent = this.originalButtonText
      }
    }

    // Remove loading indicator
    this.removeLoadingIndicator()
  }

  createLoadingIndicator() {
    if (document.getElementById("hashcash-loading")) {
      return
    }

    const indicator = document.createElement("div")
    indicator.id = "hashcash-loading"
    indicator.className = "mt-3 flex items-center gap-2 text-sm text-slate-600"
    indicator.innerHTML = `
      <svg class="animate-spin h-4 w-4 text-rose-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>Verifying your submission is legitimate...</span>
    `

    // Insert after submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.parentElement.appendChild(indicator)
    }
  }

  removeLoadingIndicator() {
    const indicator = document.getElementById("hashcash-loading")
    if (indicator) {
      indicator.remove()
    }
  }

  showError() {
    const errorDiv = document.createElement("div")
    errorDiv.className = "mt-3 rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700"
    errorDiv.innerHTML = `
      <p class="font-semibold">Verification failed</p>
      <p>We couldn't verify your submission. Please try again or contact support if the problem persists.</p>
    `

    // Insert after submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.parentElement.appendChild(errorDiv)
    }
  }
}
