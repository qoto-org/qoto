# frozen_string_literal: true

module ApplicationExtension
  extend ActiveSupport::Concern

  included do
    validates :name, length: { maximum: 60 }
    validates :website, url: true, length: { maximum: 2_000 }, if: :website?
    validates :redirect_uri, length: { maximum: 2_000 }
  end

  def most_recently_used_access_token
    @most_recently_used_access_token ||= access_tokens.where.not(last_used_at: nil).order(last_used_at: :desc).first
  end

  def grouped_scopes
    scope_map = {}

    scopes.each do |scope|
      type, area = scope.split(':')

      if %w(read write).include?(type)
        area ||= 'all'
        (scope_map[area] ||= []) << type
      else
        scope_map[type] = %w(read write)
      end
    end

    scope_map
  end
end
