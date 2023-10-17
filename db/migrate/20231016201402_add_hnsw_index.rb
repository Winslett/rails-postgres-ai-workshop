class AddHnswIndex < ActiveRecord::Migration[7.1]
  def change
    ActiveRecord::Base.connection.execute(<<SQL)
CREATE INDEX recipe_embeddings_embedding ON recipe_embeddings
USING hnsw (embedding vector_l2_ops)
  WITH (m = 4, ef_construction = 10);
SQL
  end
end
