# This model reflects a label from github and is associated to Pull Requests
class Label < ActiveRecord::Base
  has_and_belongs_to_many :pull_requests

  # Prepend a # before the hex color so that it can be used in HTML
  def bg_color_for_html
    "##{color}"
  end

  # Decide if the foreground needs to be white or black to provide enough contrast compared to the color
  def fg_color_for_html
    rgb = color.hex
    r = rgb >> 16
    g = (rgb & 65280) >> 8
    b = rgb & 255
    brightness = r * 0.299 + g * 0.587 + b * 0.114
    (brightness > 160) ? '#000' : '#fff'
  end
end
