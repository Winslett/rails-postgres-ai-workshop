class RecommendedCache < ApplicationRecord

  belongs_to :recipe
  belongs_to :recommended_recipe, class_name: 'Recipe'

end
