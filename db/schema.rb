# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_10_16_202038) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

# Could not dump table "recipe_embeddings" because of following StandardError
#   Unknown type 'vector(1536)' for column 'embedding'

  create_table "recipes", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recommended_caches", primary_key: ["recipe_id", "rank"], force: :cascade do |t|
    t.integer "rank", null: false
    t.bigint "recipe_id", null: false
    t.bigint "recommended_recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_recommended_caches_on_recipe_id"
    t.index ["recommended_recipe_id"], name: "index_recommended_caches_on_recommended_recipe_id"
  end

  add_foreign_key "recipe_embeddings", "recipes"
  add_foreign_key "recommended_caches", "recipes"
  add_foreign_key "recommended_caches", "recipes", column: "recommended_recipe_id"
end
