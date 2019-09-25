require 'rspec/core/shared_context'

module AreaSubareaCommonHelpers
  extend RSpec::Core::SharedContext

  def area_checkbox(name)
    name = name.gsub(/\s/,'').underscore
    page.find(:xpath, ".//form[contains(@class,'mandates')]//input[@id='#{name}']")
  end

  def subarea_checkbox(group, text)
    within "##{group}_area" do
      find(:xpath, ".//div[@class='row subarea'][.//label[contains(.,'#{text}')]]//input")
    end
  end
end


