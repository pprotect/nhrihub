require 'rails_helper'

describe "#next" do
  context "when reminder_type is weekly" do
    let(:reminder){ Reminder.new(:reminder_type => 'weekly', :start_date => start_date)}
    let(:reminder_next){ reminder.send(:next_reminder_date) }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the first day in the future which is the same day as the start day" do
        expect(reminder_next.days_to_week_start).to eq start_date.days_to_week_start
        expect(reminder_next.future?).to eq true
        expect((reminder_next - Date.today).to_i).to be < 7
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date
      end
    end
  end

  context "when reminder_type is monthly" do
    let(:reminder){ Reminder.new(:reminder_type => 'monthly', :start_date => start_date)}
    let(:reminder_next){ reminder.send(:next_reminder_date) }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the first day in the future which is the same day-of-the-month as the start day" do
        expect(reminder_next.day).to eq start_date.day
        expect(reminder_next.future?).to eq true
        expect((reminder_next - Date.today).to_i).to be < 31
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date
      end
    end
  end

  context "when reminder_type is quarterly" do
    let(:reminder){ Reminder.new(:reminder_type => 'quarterly', :start_date => start_date)}
    let(:reminder_next){ reminder.send(:next_reminder_date) }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the first day in the future which is the same day-of-the-quarter as the start day" do
        expect(reminder_next.day).to eq start_date.day
        expect(reminder_next.future?).to eq true
        expect((reminder_next.month - Date.today.month).to_i).to be <= 3
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date
      end
    end
  end

  context "when reminder_type is semi-annually" do
    let(:reminder){ Reminder.new(:reminder_type => 'semi-annually', :start_date => start_date)}
    let(:reminder_next){ reminder.send(:next_reminder_date) }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the first day in the future which is the same day-of-the-half-year as the start day" do
        expect(reminder_next.day).to eq start_date.day
        expect(reminder_next.future?).to eq true
        expect((reminder_next.month - Date.today.month).to_i).to be <= 6
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date
      end
    end
  end

  context "when reminder_type is annually" do
    let(:reminder){ Reminder.new(:reminder_type => 'annually', :start_date => start_date)}
    let(:reminder_next){ reminder.send(:next_reminder_date) }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the first day in the future which is the same day-of-the-year as the start day" do
        expect(reminder_next.day).to eq start_date.day
        expect(reminder_next.future?).to eq true
        expect((reminder_next.month - Date.today.month).to_i).to be <= 12
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date
      end
    end
  end

  context "when reminder_type is one-time" do
    let(:reminder){ Reminder.new(:reminder_type => 'one-time', :start_date => start_date)}
    let(:reminder_next){ reminder.next }
    let(:reminder_previous){ reminder.previous }
    context "and start date is in the past" do
      let(:start_date){ Date.new(2015,8,1)}
      it "should be the 'none'" do
        expect(reminder_next).to eq 'none'
        expect(reminder_previous).to eq start_date.to_formatted_s(:default)
      end
    end

    context "and start_date is in the future" do
      let(:start_date){ Date.new(2020,8,1)}
      it "should be equal to the start date" do
        expect(reminder_next).to eq start_date.to_formatted_s(:default)
        expect(reminder_previous).to eq 'none'
      end
    end
  end
end