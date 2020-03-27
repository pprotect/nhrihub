require 'erb'

class Excess::Template < Excess::Base
  def initialize(template, view_assigns)
    view_assigns.keys.each do |key|
      instance_variable_set("@"+key, view_assigns[key])
    end
    create_template(template)
  end

  def create_template(template)
    src = Pathname(template).absolute? ? template : Rails.application.root.join("app", template)
    FileUtils.cp_r(src , Rails.application.root.join('tmp'))
    temp = template.split("/")[-1]
    FileUtils.rm_r("tmp/xlsx") if File.exists?("tmp/xlsx")
    FileUtils.mv("tmp/#{temp}","tmp/xlsx", :force => true)
  end

  def render_to_string
    source = Rails.application.root.join('tmp/xlsx')
    zip_package(source)
    read_zipfile
  end
end
