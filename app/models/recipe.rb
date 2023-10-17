class Recipe < ApplicationRecord

  has_one :recipe_embedding

  has_many :recommended_cache, -> { order('rank') }
  has_many :recommended_recipes, through: :recommended_cache

  def recommended(limit = 5)
    r = self.recommended_recipes.limit(limit)
    if r.length == limit
      r
    else
      recommended_recipes = Recipe.find_by_sql([<<-SQL, self.id, limit + 1, self.id])
        WITH recipe_embeddings AS (
          SELECT
            recipe_embeddings.recipe_id
          FROM recipe_embeddings
          ORDER BY recipe_embeddings.embedding <-> (SELECT embedding FROM recipe_embeddings WHERE recipe_id = ?)
          LIMIT ?
        )

        SELECT
          recipes.id AS id,
          recipes.name AS name
        FROM recipes
        WHERE recipes.id IN (SELECT recipe_id FROM recipe_embeddings)
          AND recipes.id != ?
SQL

      recommended_recipes.each_with_index do |recommended_recipe, i|
        RecommendedCache.upsert({recipe_id: self.id, rank: i, recommended_recipe_id: recommended_recipe.id})
      end

      recommended_recipes
    end
  end

  def self.search(q, limit = 20)
    openai = OpenAI::Client.new(access_token: Rails.application.credentials.openai.api_key)
    response = openai.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: q
      }
    )

    q_embeddings = response["data"][0]["embedding"].to_s

    Recipe.find_by_sql([<<-SQL, q_embeddings, limit])
      SELECT
        recipes.id,
        recipes.name,
        recipes.description,
        recipes.created_at,
        recipes.updated_at
      FROM recipe_embeddings
        INNER JOIN recipes ON recipe_embeddings.recipe_id = recipes.id
      ORDER BY recipe_embeddings.embedding <-> ?
      LIMIT ?
SQL
  end

end
