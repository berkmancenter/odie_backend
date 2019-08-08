class DataCollectionsController < ApplicationController
  layout 'admin'

  def new
  end
end

# Is this what I want at all? Should this be a controller for the DataConfig,
# which could be dealt with in the admin in a more normal way? Is there a
# DataCollectionRun which belongs in admin and governs configs? hmmm....
