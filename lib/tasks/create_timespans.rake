require 'rake'

namespace :odie do
  desc 'Create any timespans that are ready to be created'
  task :create_timespans, [:start_date, :end_date] => [:environment] do |t, args|
    if args.start_date.nil?
      start_date = 1.day.ago.to_date
    else
      start_date = Date.parse(args.start_date)
    end

    if args.end_date.nil?
      end_date = Date.today
    else
      end_date = Date.parse(args.end_date)
    end

    if !Rails.env.test?
      puts "Creating missing timespans from #{start_date} to #{end_date}"
    end
    today = start_date
    while today < end_date
      if Timespan.day_long.where(start: today).count == 0
        t = Timespan.create!(start: today, in_seconds: Timespan::DAY_DURATION)
      end

      if ((end_date - today).days >= Timespan::WEEK_DURATION &&
         Timespan.week_long.where(start: today).count == 0)
        t = Timespan.create!(start: today, in_seconds: Timespan::WEEK_DURATION)
      end
      today += 1.day
    end
  end
end
