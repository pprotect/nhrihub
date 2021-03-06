RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # additional factory_bot configuration

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryBot.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
