module Complaints::ValidationHelper
  attr_accessor :row_number

  def header
    @row_number = 0
    xml = Builder::XmlMarkup.new
    xml.row :r => @row_number +=1, :s => "4", :customFormat => "1" do
      xml << cell(:col => "A", :row => @row_number, :style => "3", :type => "inlineStr", :contents => "Case ref.")
      xml << cell(:col => "B", :row => @row_number, :style => "3", :type => "inlineStr", :contents => "Original")
      xml << cell(:col => "C", :row => @row_number, :style => "3", :type => "inlineStr", :contents => "Analysed as")
    end
    xml.row :r => @row_number +=1, :s => "4", :customFormat => "1", :ht => "70" do
      headings.each_with_index do |heading,column_index|
        xml << cell(:col => alpha(column_index),
                    :row => @row_number,
                    :style => "3",
                    :type => "inlineStr",
                    :contents => heading)
      end #/row.each
    end
    xml
  end

  def mergeCells
    #cell_ranges = ["A3:A4","B1:K1","M1:AI1"]
    cell_ranges = ["C1:G1"]
    xml = Builder::XmlMarkup.new

    xml.mergeCells :count => cell_ranges.length do
      cell_ranges.each do |mergeCell|
        xml.mergeCell :ref => mergeCell
      end
    end
  end

  def errors
    xml = Builder::XmlMarkup.new
    @report.errored_records.each do |errored_record|
      xml.row :r => @row_number += 1 do
        errored_record.each_with_index do |val,i|
          xml << cell(:col => alpha(i), :row => @row_number, :style => "5", :type => "inlineStr", :contents => val)
        end
      end
    end
    xml
  end

  def totals
    xml = Builder::XmlMarkup.new
    xml.row :r => @row_number += 1 do
      xml << cell(:col => "A", :row => @row_number, :style => "5", :type => "inlineStr", :contents => "total lines analysed")
      xml << cell(:col => "B", :row => @row_number, :style => "5", :type => "inlineStr", :contents => @report.lines_analysed)
    end
    xml.row :r => @row_number += 1 do
      xml << cell(:col => "A", :row => @row_number, :style => "5", :type => "inlineStr", :contents => "errored records found")
      xml << cell(:col => "B", :row => @row_number, :style => "5", :type => "inlineStr", :contents => @report.errors_found)
    end
  end


private
  def headings
    ["", @report.column_name]
  end

  def alpha(index)
    ("A".."BZ").to_a[index]
  end
end
