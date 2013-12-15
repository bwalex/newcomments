require 'sass'
require 'sass/plugin'

Sass::Plugin.options.merge!(
  :style => :compact,
  :template_location => "./views/stylesheets",
  :css_location => "./public/assets/stylesheets"
)

