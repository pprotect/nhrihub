require 'rspec/core/shared_context'

module MediaSpecHelper
  extend RSpec::Core::SharedContext
  def single_item_selector
    '#media_appearances .media_appearance'
  end

  def media_appearances
    page.all(single_item_selector)
  end

  def expand_all_panels
    page.find('#media_appearances_controls #expand').click
    sleep(0.3)
  end

  def first_article_link
    MediaAppearance.first.article_link.gsub(/http/,'')
  end

  def delete_article_link_field
    fill_in("media_appearance_article_link", :with => "")
  end

  def number_of_rendered_media_appearances
    page.all(single_item_selector).length
  end

  def number_of_all_media_appearances
    page.all(single_item_selector, :visible => false).length
  end

end
