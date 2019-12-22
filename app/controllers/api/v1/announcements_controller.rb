# frozen_string_literal: true

class Api::V1::AnnouncementsController < Api::BaseController
  before_action :set_announcements

  def index
    render json: @announcements, each_serializer: REST::AnnouncementSerializer
  end

  private

  def set_announcements
    @announcements = Announcement.live
  end
end
