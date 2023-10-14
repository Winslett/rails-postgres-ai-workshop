class Recipe < ApplicationRecord

  has_many :recipe_embeddings

  def recommended(limit = 5)
    recipe_ids = RecipeEmbedding.find_by_sql([<<-SQL, self.id, limit + 1]).map(&:recipe_id)
    SELECT
      re2.recipe_id
    FROM recipe_embeddings AS re1, recipe_embeddings AS re2
    WHERE re1.recipe_id = ?
    ORDER BY re1.embedding <-> re2.embedding
    LIMIT ?
SQL

    Recipe.where(id: recipe_ids - [self.id])
  end
end
