require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "reminder" do
    let(:user) { FactoryBot.create(:user, :email => "norm@acme.org") }
    let(:complaint) { FactoryBot.create(:complaint) }
    let(:reminder){ FactoryBot.build(:reminder, :complaint, :remindable_id => complaint.id, :user => user) }
    let(:mail) { ReminderMailer.reminder(reminder) }

    it "renders the headers" do
      expect(mail.subject).to eq("A reminder from #{APPLICATION_NAME}")
      expect(mail.to).to eq(["norm@acme.org"])
      expect(mail.from).to eq([NO_REPLY_EMAIL])
    end

    it "renders the body" do
      #puts mail.body.encoded
      #puts reminder.text
      expect(mail.body.encoded).to match(reminder.text)
      expect(mail.body.encoded).to include(reminder.link)
    end

    it "includes link with full path to the originating page" do
      html = mail.body.parts[1].body.raw_source
      html = Nokogiri::HTML(html)
      source_link = html.xpath(".//a[@id='source_link']/@href").text
      unsubscribe_url = html.xpath(".//a[@id='opt_out_link']/@href").text
      url = URI.parse(source_link)
      expect(url.host).to eq SITE_URL
      expect(url.path).to eq "/en/complaints"
      params = CGI.parse(url.query)
      expect(params.keys.first).to eq "case_reference"
      expect(params.values.first).to eq ["some string"]
      expect( mail.header_fields.find{|h| h.name == 'From'}.value).to eq "NHRI Hub Administrator<no_reply@nhri-hub.com>"
      expect( mail.header_fields.find{|h| h.name == 'List-Unsubscribe-Post'}.value).to eq "List-Unsubscribe=One-Click"
      expect( mail.header_fields.find{|h| h.name == 'List-Unsubscribe'}.value).to eq admin_unsubscribe_url(:en,user.id, user.reload.unsubscribe_code, host: SITE_URL, protocol: :https)
      expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code
    end
  end
end
