# frozen_string_literal: true

class Api::V1::TagsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :follow, :write, :'write:follows' }
  before_action :require_user!
  before_action :set_tag, except: :follow
  before_action :set_or_create_tag, only: :follow

  override_rate_limit_headers :follow, family: :follows

  def show
    render json: @tag, serializer: REST::TagSerializer
  end

  def follow
    TagFollow.create!(tag: @tag, account: current_account, rate_limit: true)
    render_empty
  end

  def unfollow
    TagFollow.find_by(account: current_account, tag: @tag)&.destroy!
    render_empty
  end

  private

  def set_tag
    @tag = Tag.find_normalized!(params[:id])
  end

  def set_or_create_tag
    @tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
  end
end
