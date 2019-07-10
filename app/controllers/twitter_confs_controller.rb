# frozen_string_literal: true

class TwitterConfsController < ActionController::Base
  FILENAME = "#{Rails.root}/logstash/config/twitter.conf"

  def new
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
    File.write(FILENAME, conf)
  end

  def context
    @context ||= begin
      keywords = sanitize(DataConfig.find(params[:id]).keywords)
      context = binding
      context.local_variable_set(:env, ENV)
      context
    end
  end

  private

  def sanitize(keywords)
    keywords.map { |kw| URI.encode(kw) }
  end
end