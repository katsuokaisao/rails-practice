# frozen_string_literal: true

require 'open3'

namespace :db do
  namespace :custom do
    desc 'Reset & apply ridgepole, then seed (development)'
    task setup: :environment do
      reset_database(env: 'development')
      run_ridgepole(env: 'development')
      run_annotaterb
      seed!(env: 'development')
    end

    desc 'Reset & apply ridgepole (test)'
    task setup_test: :environment do
      reset_database(env: 'test')
      run_ridgepole(env: 'test')
    end

    desc 'Ridgepole dry-run (development)'
    task ridgepole_dry_run: :environment do
      run_ridgepole(env: 'development', dry_run: true)
    end

    desc 'Ridgepole apply (development)'
    task ridgepole_apply: :environment do
      run_ridgepole(env: 'development')
    end

    desc 'Ridgepole export (development)'
    task ridgepole_export: :environment do
      run_ridgepole_export
    end

    private

    def reset_database(env: 'development')
      puts '-- Reset database'
      run!('bin/rake', 'db:drop', env: { 'RAILS_ENV' => env })
      run!('bin/rake', 'db:create', env: { 'RAILS_ENV' => env })
    end

    def run_ridgepole(env: 'development', dry_run: false)
      args = ['bundle', 'exec', 'ridgepole',
              '-c', 'config/database.yml',
              '-f', 'db/schemas/Schemafile',
              '-E', env,
              '--apply']
      args << '--dry-run' if dry_run
      run!(*args)
    end

    def run_ridgepole_export(env: 'development')
      args = ['bundle', 'exec', 'ridgepole',
              '-c', 'config/database.yml',
              '-E', env,
              '-o', 'db/schemas/export_schema',
              '--export']
      run!(*args)
    end

    def run_annotaterb
      args = %w[bundle exec annotaterb models]
      run!(*args)
    end

    def seed!(env: 'development')
      run!('bin/rails', 'db:seed', env: { 'RAILS_ENV' => env })
    end

    def run!(*args, env: {})
      puts ([env.map { |k, v| "#{k}=#{v}" }.join(' ')] + args).reject(&:empty?).join(' ')

      stdout, stderr, status = Open3.capture3(env, *args)

      puts stdout unless stdout.empty?
      warn stderr unless stderr.empty?

      abort("FAILED: #{args.inspect}") unless status.success?
    end
  end
end
