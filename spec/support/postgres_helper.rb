module PostgresHelper
  attr_accessor :location
  def with_capture(location, *tables)
    @location = location.constantize.root.join('spec', 'seeds')
    if ENV["capture"] == "true"
      yield
      capture(tables)
    else
      replay(tables)
    end
  end

  def capture(tables)
    tables.each do |table|
      capture_table(table)
    end
  end

  def replay(tables)
    tables.each do |table|
      replay_table(table)
    end
  end

  private
  def capture_table(table)
    ActiveRecord::Base.connection.execute("copy #{table} to '#{file(table)}'")
  end

  def replay_table(table)
    ActiveRecord::Base.connection.execute("copy #{table} from '#{file(table)}'")
    ActiveRecord::Base.connection.execute("select setval ('#{table}_id_seq', (select max(id) from #{table})+1)")
  end

  def file(table)
    #Complaints::Engine.root.join('spec','seeds',"#{table}.txt")
    location.join("#{table}.txt")
  end
end

RSpec.configure do |config|
  config.include PostgresHelper, type: :feature
end
