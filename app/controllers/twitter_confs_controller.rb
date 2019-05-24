class TwitterConfsController < ActionController::Base
  def new
    # Later we will do something like the following, to extract real data
    # from a real config file. Right now we're using dummy variables to test
    # that we can write a config file at all.
    # config = params[:config]
    # keywords = config.media_sources.pluck(:keyword).uniq
    # get most recent config (or else config from params)
    # write file to config
    # handling in case there is some kind of interruption? active ~config~
    # is not guaranteed to be the same as active ~file~
    keywords
    context = binding
    context.local_variable_set(:env, ENV)

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
    filename = "#{Rails.root}/logstash/config/twitter.conf"
    File.write(filename, conf)
  end
end
