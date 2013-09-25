ENV["RAILS_ENV"] = "test"

require "test/unit"
require "mocha/setup"
require "minitest/reporters"
MiniTest::Reporters.use!

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean_with(:truncation)

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  #

  def prepare_email
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    return ActionMailer::Base.deliveries
  end


  # Add more helper methods to be used by all tests here...
  def login(user=nil)
    user ||= FactoryGirl.create(:user)
    sign_in :user, user
    return user
  end

  def admin_login(user=nil)
    admin = login(user)
    admin.make_admin!
    return admin
  end

  def assert_include(expected, value)
    assert_kind_of Array, value
    assert value.include?(expected)
  end

  def assert_empty(value)
    assert_kind_of Array, value
    assert value.empty?
  end

  def assert_not_empty(value)
    assert_kind_of Array, value
    assert !value.empty?
  end

end

class ActionController::TestCase
  include Devise::TestHelpers

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end
