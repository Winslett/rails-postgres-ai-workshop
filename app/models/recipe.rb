class Recipe < ApplicationRecord

  has_many :recipe_embeddings
  has_many :recommended_cache, -> { order('rank') }
  has_many :recommended_recipes, through: :recommended_cache

  def recommended(limit = 5)
    r = self.recommended_recipes.limit(limit)
    if r.length == limit
      r
    else
      recipe_ids = RecipeEmbedding.find_by_sql([<<-SQL, self.id, limit + 1]).map(&:recipe_id)
        SELECT
          re2.recipe_id
        FROM recipe_embeddings AS re1, recipe_embeddings AS re2
        WHERE re1.recipe_id = ?
        ORDER BY re1.embedding <-> re2.embedding
        LIMIT ?
      SQL

      recipe_ids = recipe_ids - [self.id] # we do not filter out the recipe above because it wouldn't use the index

      recipe_ids.each_with_index do |recipe_id, i|
        RecommendedCache.upsert({recipe_id: self.id, rank: i, recommended_recipe_id: recipe_id})
      end

      Recipe.where(id: recipe_ids)
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
