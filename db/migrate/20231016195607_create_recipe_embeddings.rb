class CreateRecipeEmbeddings < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS vector;")

    create_table :recipe_embeddings, primary_key: [:recipe_id] do |t|
      t.references :recipe, null: false, foreign_key: true
      t.column :embedding, "vector(1536)", null: false

      t.timestamps
    end
  end
end
