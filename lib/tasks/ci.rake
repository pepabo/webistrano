require "fileutils"

desc "Run the Continuous Integration tests"
task :ci do
  # RAILS_ENV and ENV[] can diverge so force them both to test
  ENV['RAILS_ENV'] = 'test'
  RAILS_ENV = 'test'
  Rake::Task["ci:setup"].invoke
  Rake::Task["ci:build"].invoke
  Rake::Task["ci:teardown"].invoke
end

namespace :ci do
  task :setup do
    Rake::Task["tmp:clear"].invoke
    Rake::Task["log:clear"].invoke
    Rake::Task["config/database.yml"].invoke
    Rake::Task["config/initializers/devise.rb"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end

  task :build do
    # if test_suite = ENV['TEST_SUITE']
    #   Rake::Task["test:#{test_suite}"].invoke
    # else
      Rake::Task["test"].invoke
    # end
  end

  task :teardown do
    FileUtils.rm('config/initializers/devise.rb', force: true)
    FileUtils.rm('config/initializers/devise.rb', force: true)
  end
end

desc "Creates initializers/devise.rb for the CI server"
file 'config/initializers/devise.rb' do
  FileUtils.cp "test/support/devise.rb", "config/initializers/devise.rb"
end

desc "Creates database.yml for the CI server"
file 'config/database.yml' do
  FileUtils.cp "config/database.yml.sample", "config/database.yml"
end
