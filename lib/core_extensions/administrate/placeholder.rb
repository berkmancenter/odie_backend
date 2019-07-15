# frozen_string_literal: true
module CoreExtensions
  module Administrate
    module Placeholder
      # This allows Administrate::Field subclasses to take :placeholder in
      # with_options, so that placeholder text can appear in the form.
      # A suitable template for the subclass must also be defined in
      # app/views/fields/[subclass]/_form.html.erb.
      def placeholder
        options.fetch(:placeholder, '')
      end
    end
  end
end
