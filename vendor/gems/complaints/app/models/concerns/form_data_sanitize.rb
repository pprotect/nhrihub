class FormDataSanitize
  # workaround hack b/c FormData object sends "null" string for null values
  # TODO refactor methods here
  def self.before_save(model)
    string_or_text_columns = model.class.columns.select{|c| (c.type == :string) || (c.type == :text)}.map(&:name)
    string_or_text_columns.each do |column_name|
      model.send("#{column_name}=", nil) if model.send(column_name) == "null" || model.send(column_name) == "undefined"
    end
    integer_columns = model.class.columns.select{|c| c.type == :integer}.map(&:name)
    # it's a hack... TODO there must be a better way!
    integer_columns.each do |column_name|
      ## an integer columm returns a string value from ActiveRecord if it is an enum type
      model.send("#{column_name}=",nil) if model.send(column_name).nil? || model.send(column_name).zero? unless model.send(column_name).is_a?(String)
    end
  end
end
