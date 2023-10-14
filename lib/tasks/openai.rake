namespace :openai do

  desc "Send recipes to OpenAI for embedding"
  task :build_recipe_embeddings => :environment do
    openai = OpenAI::Client.new(access_token: Rails.application.credentials.openai.api_key)

    recipes_without_embeddings = Recipe.where.not(description: nil)
      .left_joins(:recipe_embeddings).where(recipe_embeddings: {recipe_id: nil})

    recipes_without_embeddings.each do |recipe|
      submitted_value = recipe.description.gsub(/\n/, ' ')

      response = openai.embeddings(
        parameters: {
          model: 'text-embedding-ada-002',
          input: submitted_value
        }
      )

      begin
        embedding_value = response["data"][0]["embedding"].to_s
        RecipeEmbedding.create!(recipe: recipe, embedding: embedding_value)
      rescue
        puts [$!, response].inspect
      end

      sleep 1.2
    end
  end
end
