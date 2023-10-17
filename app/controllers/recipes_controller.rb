class RecipesController < ApplicationController

  def index
    @recipes = if params[:q].present?
                  Recipe.search(params[:q])
                else
                  Recipe.all
                end
  end

  def show
    @recipe = Recipe.find(params[:id])
  end
end
