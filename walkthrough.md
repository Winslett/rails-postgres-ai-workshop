1. The `main` branch is the final state.  To start with this walk-through, run `git checkout start_here` to start with that branch

2. Run `rails db:drop && rails db:create && rail db:migrate && rails db:seed` -- start the app with your preferred way. If you don't have a preferred way, run `rails s`

3. Add to Gemfile && bundle install

```
gem 'ruby-openai'
```

run

```
bundle install
```

4. Run the following:

```
rails g model RecipeEmbedding
```

5. Add the following to the latest migration && run `rails db:migrate`

```
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS vector;")

    create_table :recipe_embeddings, primary_key: [:recipe_id] do |t|
      t.references :recipe, null: false, foreign_key: true
      t.column :embedding, "vector(1536)", null: false

      t.timestamps
    end
```

6. Add the following associations to our models:

`app/models/recipe_embedding.rb`
```
belongs_to :recipe

```

`app/models/recipe.rb`
```
has_one :recipe_embedding
```

7. `EDITOR=vim rails credentials:edit --environment development`

```
openai:
 api_key: <a key that you get from openai>
```

8. Add the file `lib/tasks/openai.rake`

```
namespace :openai do

  desc "Send recipes to OpenAI for embedding"
  task :build_recipe_embeddings => :environment do
    openai = OpenAI::Client.new(access_token: Rails.application.credentials.openai.api_key)

    recipes_without_embedding = Recipe.where.not(description: nil)
      .left_joins(:recipe_embedding).where(recipe_embedding: {recipe_id: nil})

    recipes_without_embedding.each do |recipe|
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
```

9. rake openai:build_recipe_embeddings

```
psql rails_postgres_ai_workshop_development
```

10. Open the recipes#show page in the browser

11. add to `app/views/recipes/show.erb.html` && refresh page


```
        <dl class="divide-y divide-gray-100">
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Similar</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              <ul>
              <% @recipe.recommended.each do |recipe| %>
                <li><%= link_to recipe.name, recipe_path(recipe) %></li>
              <% end %>
              </ul>
            </dd>
          </div>
        </dl>
```

12. Add the following to the app/models/recipe.rb:

```
  def recommended(limit = 5)
    recipe_ids = RecipeEmbedding.find_by_sql([<<-SQL, self.id, limit]).map(&:recipe_id)
    SELECT
      re2.recipe_id
    FROM recipe_embeddings AS re1, recipe_embeddings AS re2
    WHERE re1.recipe_id = ?
      AND re1.recipe_id != re2.recipe_id
    ORDER BY re1.embedding <-> re2.embedding
    LIMIT ?
SQL

    Recipe.where(id: recipe_ids)
  end
```

13. Now go back and refresh the page to see that the recommendations are showing:

14. Now, open `psql rails_postgres_ai_workshop_development` and highlight the 'rows=710' at the bottom as being a table scan:

```
EXPLAIN SELECT
      re2.recipe_id
    FROM recipe_embeddings AS re1, recipe_embeddings AS re2
    WHERE re1.recipe_id = 1
      AND re1.recipe_id != re2.recipe_id
    ORDER BY re1.embedding <-> re2.embedding
    LIMIT 5;
```

15. Let's use a migration to add an index:

```
rails g migration add_hnsw_index
```

```
  def change
    ActiveRecord::Base.connection.execute(<<SQL)
CREATE INDEX recipe_embeddings_embedding ON recipe_embeddings
USING hnsw (embedding vector_l2_ops)
  WITH (m = 4, ef_construction = 10);
SQL
  end
```

```
rails db:migrate
```

16. Now, open `psql rails_postgres_ai_workshop_development` and highlight the 'rows=710' at the bottom as being a table scan:

```
EXPLAIN SELECT
      re2.recipe_id
    FROM recipe_embeddings AS re1, recipe_embeddings AS re2
    WHERE re1.recipe_id = 1
      AND re1.recipe_id != re2.recipe_id
    ORDER BY re1.embedding <-> re2.embedding
    LIMIT 5;
```

17. Open app/models/recipe.rb and change the recommended method to:

```
  def recommended(limit = 5)
    Recipe.find_by_sql([<<-SQL, self.id, limit + 1, self.id])
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
  end
```

18. Create a cache model for the Rails application, run the following:

```
rails g model recommended_cache
```

19. Edit the latest migration the add the following:

```
    create_table :recommended_caches, primary_key: [:recipe_id, :rank] do |t|
      t.integer :rank

      t.references :recipe, null: false, foreign_key: true
      t.references :recommended_recipe, null: false, foreign_key: { to_table: :recipes }

      t.timestamps
    end
```

run

```
rails db:migrate
```

20. Add the `app/models/recommended_cache.rb`

```
  belongs_to :recipe
  belongs_to :recommended_recipe, class_name: 'Recipe'
```

21. Add the following to app/models/recipe.rb

```
  has_many :recommended_cache, -> { order('rank') }
  has_many :recommended_recipes, through: :recommended_cache
```

```
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
```

22. Now, go refresh the page, and you'll see that the recommendations are still there, but the page loads faster at scale

23. For search, add the following to the `app/views/recipes/index.html.erb`:

```
  <!-- add a search box -->
  <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
    <%= form_for :search, url: recipes_path, method: :get do |f| %>
      <div class="space-y-12">
        <div class="border-b border-gray-900/10 pb-12">
          <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
            <div class="sm:col-span-4">
              <label for="q" class="block text-sm font-medium leading-6 text-gray-900">Search Recipes</label>
              <div class="mt-2">
                <div class="flex rounded-md shadow-sm ring-1 ring-inset ring-gray-300 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-600 sm:max-w-md">
                  <input type="text" name="q" id="q" class="block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6" value="<%= params[:q] %>" placeholder="spaghetti">
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
  </div>
```

24. Change the index method on `app/controllers/recipes_controller.rb` to:

```
  def index
    @recipes = if params[:q].present?
                  Recipe.search(params[:q])
                else
                  Recipe.all
                end
  end
```

25. Add the following to the `app/models/recipe.rb`

```
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
```
