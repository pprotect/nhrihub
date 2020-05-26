module ApplicationHelpers
  #TODO this can be omitted now as browser is started at this size...
  #this no longer works with chrome >= v57
  def resize_browser_window
    #if page.driver.browser.is_a?(Capybara::RackTest::Browser)
      #return
    #elsif page.driver.browser.respond_to?(:manage)
      #page.driver.browser.manage.window.resize_to(1400,800) # b/c selenium driver doesn't seem to click when target is not in the view
    #else
      #page.driver.browser.resize(1400,800)
    #end
  end

  def check(el)
    scroll_to_and_check(el)
  end

  def choose(el)
    scroll_to_and_choose(el)
  end

  def scroll_to_and_check(el)
    scroll_to(page.find_field(el))
    page.check(el)
  end

  def scroll_to_and_choose(el)
    scroll_to(page.find_field(el))
    page.choose(el)
  end

  def scroll_to_and_uncheck(el)
    scroll_to(page.find_field(el))
    page.uncheck(el)
  end

  def scroll_to(field)
    js = <<-JS
      el=document.evaluate('#{field.path}',document)\;
      itn=el.iterateNext()\;
      tt = itn.getBoundingClientRect().top\;
      scrollBy({left:0, top:tt-100})\;
    JS
    page.execute_script(js)
    field
  end

  def find(method=:css, selector)
    scroll_to(page.find(method, selector))
  end

  def select_date(date,options)
    base = options[:from].to_s
    year_selector = base+"_1i"
    month_selector = base+"_2i"
    day_selector = base+"_3i"
    month,day,year = date.split(' ')
    select(year, :from => year_selector)
    select(month, :from => month_selector)
    select(day, :from => day_selector)
  end

  def flash_message
    if ( page.find(".message_block").text rescue false)
      rails_flash = page.find(".message_block").text
      return rails_flash unless rails_flash.blank?
    end
    if (page.find('#jflash') rescue false)
      javascript_flash = page.find('#jflash').text
      return javascript_flash unless javascript_flash.blank?
    end
  end

  def navigation_menu
    page.all(".nav.navbar-nav li a").map(&:text)
  end

  def page_heading
    page.find("h1").text
  end

  def page_title
    page.driver.title
  end

  def page!
    save_and_open_page
  end

  # Saves page to place specfied at in configuration.
  # NOTE: you must pass js: true for the feature definition (or else you'll see that render doesn't exist!)
  # call force = true, or set ENV[RENDER_SCREENSHOTS] == 'YES'
  def render_page(name, force = false)
    if force || (ENV['RENDER_SCREENSHOTS'] == 'YES')
      path = File.join Rails.application.config.integration_test_render_dir, "#{name}.png"
      page.driver.render(path)
    end
  end

  def confirm_deletion
    page.find('.modal#confirm-delete a#confirm').click
  end

  def test_fail_placeholder
    expect("this is a placeholder to force test fail").to eq "something else"
  end

  def clear_filter_fields
    page.all('.fa-refresh').first.click
    wait_for_ajax
  end

  def click_back_button
    page.evaluate_script('window.history.back()')
  end

  def click_forward_button
    page.evaluate_script('window.history.forward()')
  end

  def query_string
    page.evaluate_script("window.location.search")
  end

  #e.g. /en/complaints/55
  def browser_url
    page.evaluate_script('window.location.pathname')
  end
end
