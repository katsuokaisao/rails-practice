# frozen_string_literal: true

require 'fileutils'

namespace :clear do
  desc 'Remove coverage/ directory'
  task :coverage do
    path = Rails.root.join('coverage')
    if path.exist?
      FileUtils.rm_rf(path)
      puts "Removed #{path}"
    end
  end

  desc 'Remove Capybara screenshots (tmp/capybara)'
  task :screenshots do
    path = Rails.root.join('tmp/capybara')
    if path.exist?
      FileUtils.rm_rf(path)
      puts "Removed #{path}"
    end
  end

  desc 'Remove miniprofiler (tmp/miniprofiler)'
  task :miniprofiler do
    path = Rails.root.join('tmp/miniprofiler')
    if path.exist?
      FileUtils.rm_rf(path)
      puts "Removed #{path}"
    end
  end

  desc 'Clear tmp, log, coverage, screenshots (all in one)'
  task all: [] do
    Rake::Task['tmp:clear'].invoke
    Rake::Task['tmp:cache:clear'].invoke
    Rake::Task['log:clear'].invoke
    Rake::Task['clear:coverage'].invoke
    Rake::Task['clear:screenshots'].invoke
    Rake::Task['clear:miniprofiler'].invoke
  end
end
