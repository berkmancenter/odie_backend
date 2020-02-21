require "administrate/base_dashboard"

class SearchQueryDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    active: Field::Boolean,
    description: Field::Text.with_options(
      placeholder: "Will be displayed to users."
    ),
    keyword: Field::String.with_options(
      placeholder: "Don't override this without consulting the admin docs."
    ),
    name: Field::String.with_options(
      placeholder: '"Washington Post"; will be displayed to users.'
    ),
    url: Field::String.with_options(
      placeholder: 'www.washingtonpost.com'
    ),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :active,
    :description,
    :keyword,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :active,
    :description,
    :keyword,
    :name,
    :url,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :active,
    :description,
    :keyword,
    :name,
    :url,
  ].freeze

  # Overwrite this method to customize how media sources are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(search_query)
  #   "SearchQuery ##{search_query.id}"
  # end
end
