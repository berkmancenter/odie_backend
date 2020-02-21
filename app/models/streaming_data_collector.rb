# frozen_string_literal: true

class StreamingDataCollector
  def initialize(cohort_collector)
    @cohort_collector = cohort_collector
  end

  def filename
    "#{Rails.application.config.logstash_conf_dir}/#{@cohort_collector.index_name}.conf"
  end

  def write_conf
    # It would be better to create a config file and then use logstash to
    # validate it. However, we can't run system logstash in a subprocess unless
    # it was built against the same version of ruby, and coupling those doesn't
    # seem like a safe long-term strategy. Installing a logstash gem of the
    # correct version here and using its built-in validator would work in
    # theory, but in practice bundle installing that gem fails. So we'll
    # do a first-pass validation here and hope it's good enough.
    unless TwitterConf.valid?(context)
      raise 'The context is missing needed variables.'
    end
    conf = TwitterConf.generate(context)
    File.write(filename, conf)
  end

  def kickoff
    cmd = "timeout #{Rails.application.config.logstash_run_time} #{Rails.application.config.logstash_command} -f #{filename}"

    # This will detach the process so it doesn't block the main rails process.
    fork { exec(basic_env, cmd) }
  end

  private

  # When we fork, the new process is spawned with the same environment as this
  # parent process. However, that causes clashes with the vendored logstash
  # version of ruby, which cannot be guaranteed to be the same as the version
  # used by rails here, due to bundler's manipulation of the PATH. We should
  # therefore subtract out all the rails-specific env that might cause
  # problems.
  # We do want to do this subtractively, not additively (by building up an env
  # from nothing), because this code will be deployed on different machines with
  # different OSes which might have very different underlying configurations.
  # Removing the stuff rails has added will (hopefully) leave us with something
  # appropriate to the environment in which the code is running.
  # We need to actually set the values to nil rather than return an hash which
  # has removed the suspect keys, because rails will 'helpfully' add those back
  # in.
  def basic_env
    evil_keys = [Dotenv.parse('.env').keys,
                 Bundler::EnvironmentPreserver::BUNDLER_KEYS,
                 Bundler::EnvironmentPreserver::BUNDLER_KEYS.map { |k| "#{Bundler::EnvironmentPreserver::BUNDLER_PREFIX}#{k}"},
                 %w['RAILS_ENV RACK_ENV RUBY_VERSION]
               ].flatten
    evil_keys.delete('PATH') # keep this or we won't be able to find logstash

    new_env = ENV.to_h
    evil_keys.map { |k| new_env[k] = nil }

    new_env
  end

  def context
    @context ||= begin
      keywords = sanitize(@cohort_collector.keywords)
      context = binding
      context.local_variable_set(:env, ENV)
      context
    end
  end

  def sanitize(keywords)
    keywords.map { |kw| URI.encode(kw) }
  end
end
