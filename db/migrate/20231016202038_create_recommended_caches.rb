class CreateRecommendedCaches < ActiveRecord::Migration[7.1]
  def change
    create_table :recommended_caches, primary_key: [:recipe_id, :rank] do |t|
      t.integer :rank

      t.references :recipe, null: false, foreign_key: true
      t.references :recommended_recipe, null: false, foreign_key: { to_table: :recipes }

      t.timestamps
    end
  end
end
