# frozen_string_literal: true

module StreamingDataCollector
  def self.filename
    "#{Rails.application.config.logstash_conf_dir}/logstash.conf"
  end

  def self.write_basic_conf
    File.write(filename, "input { file { path => '/dev/null' } }\noutput { stdout {} }")
  end

  def self.write_conf
    # It would be better to create a config file and then use logstash to
    # validate it. However, we can't run system logstash in a subprocess unless
    # it was built against the same version of ruby, and coupling those doesn't
    # seem like a safe long-term strategy. Installing a logstash gem of the
    # correct version here and using its built-in validator would work in
    # theory, but in practice bundle installing that gem fails. So we'll
    # do a first-pass validation here and hope it's good enough.
    unless TwitterConf.valid?(vars)
      raise 'The context is missing needed variables.'
    end
    conf = TwitterConf.generate(vars)
    File.write(filename, conf)
  end

  def self.vars
    begin
      acct_ids_to_cohort_prefix = make_acct_ids_to_cohort_prefix
      context = binding
      context.local_variable_set(:env, ENV)
      context
    end
  end

  def self.make_acct_ids_to_cohort_prefix
    output = {}
    Hash[Cohort.pluck(:index_prefix, :twitter_ids)].each do |prefix, acct_ids|
      acct_ids.each{|id| output[id.to_i] = prefix}
    end
    output
  end
end
