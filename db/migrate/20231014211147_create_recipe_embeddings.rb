class CreateRecipeEmbeddings < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS vector;")

    create_table :recipe_embeddings do |t|
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end

    add_column :recipe_embeddings, :embedding, "vector(1536)", null: false
  end
end
