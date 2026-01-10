// assets/js/hooks.js
let Hooks = {};

import * as echarts from "../vendor/echarts.min"

Hooks.Chart = {
  getTextColor() {
    // Check if dark mode is active by looking at the html element's data-theme attribute
    const theme = document.documentElement.getAttribute('data-theme')
    // Return lighter color for dark themes, darker for light themes
    // If theme is null or 'system', detect based on prefers-color-scheme
    if (!theme || theme === 'system') {
      const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      return isDark ? '#f0f0f0' : '#101010'
    }
    return theme === 'dark' ? '#f0f0f0' : '#101010'
  },

  getGridLineColor() {
    const theme = document.documentElement.getAttribute('data-theme')
    // If theme is null or 'system', detect based on prefers-color-scheme
    if (!theme || theme === 'system') {
      const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      return isDark ? '#aaaaaa' : '#555555'
    }
    return theme === 'dark' ? '#aaaaaa' : '#555555'
  },

  applyThemeColors(option) {
    const textColor = this.getTextColor()
    const gridLineColor = this.getGridLineColor()

    // Deep clone to avoid mutation issues
    const newOption = JSON.parse(JSON.stringify(option))

    // Apply text color to all text elements
    if (newOption.title && newOption.title[0]) {
      newOption.title[0].textStyle = { ...newOption.title[0].textStyle, color: textColor }
    }
    if (newOption.xAxis && newOption.xAxis[0]) {
      newOption.xAxis[0].axisLabel = { ...newOption.xAxis[0].axisLabel, color: textColor }
      newOption.xAxis[0].axisLine = { lineStyle: { color: textColor } }
    }
    if (newOption.yAxis && newOption.yAxis[0]) {
      newOption.yAxis[0].nameTextStyle = { ...newOption.yAxis[0].nameTextStyle, color: textColor }
      newOption.yAxis[0].axisLabel = { ...newOption.yAxis[0].axisLabel, color: textColor }
      newOption.yAxis[0].axisLine = { lineStyle: { color: textColor } }
      newOption.yAxis[0].splitLine = { lineStyle: { color: gridLineColor } }
    }

    return newOption
  },

  render(chart, option) {
    // The legend selection should not be overridden with subsequent updates
    if (chart.getOption() && option.legend && option.legend.selected) {
      delete option.legend.selected
    }

    // Apply theme colors - need to handle the non-array format from the server
    const textColor = this.getTextColor()
    const gridLineColor = this.getGridLineColor()

    // Apply colors to the incoming option
    if (option.title) {
      option.title.textStyle = { ...option.title.textStyle, color: textColor }
    }
    if (option.xAxis) {
      option.xAxis.axisLabel = { ...option.xAxis.axisLabel, color: textColor }
      option.xAxis.axisLine = { lineStyle: { color: textColor } }
    }
    if (option.yAxis) {
      option.yAxis.axisLabel = { ...option.yAxis.axisLabel, color: textColor }
      option.yAxis.axisLine = { lineStyle: { color: textColor } }
      option.yAxis.splitLine = { lineStyle: { color: gridLineColor } }
    }

    chart.setOption(option)
  },

  mounted() {
    let chart = echarts.init(this.el)
    this.chart = chart // Store chart reference for theme handler

    this.handleEvent(`chart-option-${this.el.id}`, (option) =>
      this.render(chart, option)
    )

    // Handle window resize
    this.resizeHandler = () => {
      chart.resize()
    }
    window.addEventListener('resize', this.resizeHandler)

    // Handle theme changes via the phx:set-theme event
    this.themeHandler = () => {
      setTimeout(() => {
        const currentOption = chart.getOption()
        if (currentOption) {
          const updatedOption = this.applyThemeColors(currentOption)
          chart.setOption(updatedOption, { notMerge: false, lazyUpdate: false })
        }
      }, 100) // Small delay to let the DOM update
    }
    window.addEventListener('phx:set-theme', this.themeHandler)

    // Also handle theme changes via MutationObserver as fallback
    this.themeObserver = new MutationObserver(() => {
      const currentOption = chart.getOption()
      if (currentOption) {
        const updatedOption = this.applyThemeColors(currentOption)
        chart.setOption(updatedOption, { notMerge: false, lazyUpdate: false })
      }
    })
    this.themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    })
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
    if (this.themeHandler) {
      window.removeEventListener('phx:set-theme', this.themeHandler)
    }
    if (this.themeObserver) {
      this.themeObserver.disconnect()
    }
  }
}

export default Hooks;