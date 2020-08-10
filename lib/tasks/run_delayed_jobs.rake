require 'rake'

desc 'Run delayed jobs'
task :run_delayed_jobs do |task, args|
  # We wrap this in a rake task to make it easier to execute from cron -- this
  # way cron doesn't need to know any of the internals of how the project is
  # structured, and will automatically stay in sync should we change the
  # parameters we want to execute workers with.
  system("#{Rails.application.config.delayed_job_command}")
end
