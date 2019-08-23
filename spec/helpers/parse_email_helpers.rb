require 'rspec/core/shared_context'
module ParseEmailHelpers
  extend RSpec::Core::SharedContext
  def header_field(name)
    email.header_fields.find{|h| h.name == name}.value
  end

  def email_count
    ActionMailer::Base.deliveries.count
  end

  def sender
    xml.xpath(".//p[@id='sender']").first.text
  end

  def addressee
    xml.xpath(".//p[@id='addressee']").first.text
  end

  def email
    ActionMailer::Base.deliveries.last
  end

  def activate_url
    xml.xpath(".//p/a[@id='activate_link']/@href").first.value
  end

  def unsubscribe_url
    xml.xpath(".//p/a[@id='opt_out_link']/@href").first.value
  end

  def complaint_url
    xml.xpath(".//p/a[@id='complaint_link']/@href").first.value
  end

  private
  def xml
    Nokogiri::HTML(email.body.to_s)
  end
end
