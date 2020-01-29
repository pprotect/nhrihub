require 'rails_helper'

describe 'end_date' do
  before do
    complaint = FactoryBot.create(:complaint)
    @registered = FactoryBot.create(:status_change, :registered, complaint_id: complaint.id, change_date: DateTime.now)
    @assessment = FactoryBot.create(:status_change, :assessment, complaint_id: complaint.id, change_date: DateTime.now)
  end

  it "should add an end date to the prior status change" do
    # %Q format is seconds since start of Unix epoch
    expect(@registered.reload.end_date.strftime("%Q")).to eq @assessment.change_date.strftime("%Q")
  end
end

describe 'duration' do
  context 'when a status change is the most recent' do
    before do
      complaint = FactoryBot.create(:complaint)
      @registered = FactoryBot.create(:status_change, :registered, complaint_id: complaint.id, change_date: DateTime.now.advance(days: -5))
    end

    it "should calculate duration from change_date to now" do
      expect(@registered.duration).to eq "5 days"
    end
  end

  context 'when there are subsequent status changes' do
    before do
      complaint = FactoryBot.create(:complaint)
      @registered = FactoryBot.create(:status_change, :registered, complaint_id: complaint.id, change_date: DateTime.now.advance(days: -15))
      @assessment = FactoryBot.create(:status_change, :assessment, complaint_id: complaint.id, change_date: DateTime.now.advance(days: -5))
    end

    it "should calculate duration from change_date to end_date" do
      expect(@registered.reload.end_date).not_to be_nil
      expect(@registered.reload.duration).to eq "10 days"
    end
  end

  context 'when subsequent status change change date is not explicitly supplied' do
    before do
      complaint = FactoryBot.create(:complaint)
      @registered = FactoryBot.create(:status_change, :registered, complaint_id: complaint.id, change_date: DateTime.now.advance(days: -15))
      @assessment = FactoryBot.create(:status_change, :assessment, complaint_id: complaint.id)
    end

    it "should calculate duration from change_date to end_date" do
      expect(@registered.reload.end_date).not_to be_nil
      expect(@registered.reload.duration).to eq "15 days"
    end
  end
end
