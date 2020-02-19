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
    cmd = "timeout #{Rails.application.config.logstash_run_time} #{Rails.application.config.logstash_command} -f #{filename} &"
    system(cmd)
  end

  private

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
