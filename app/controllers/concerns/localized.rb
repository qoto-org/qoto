# frozen_string_literal: true

module Localized
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  def set_locale
    requested_locale_name   = params[:locale].presence
    requested_locale_name ||= current_user.locale if respond_to?(:user_signed_in?) && user_signed_in?
    requested_locale_name ||= request_locale unless ENV['DEFAULT_LOCALE'].present?
    requested_locale_name ||= I18n.default_locale

    I18n.with_locale(requested_locale_name) do
      yield
    end
  end

  private

  def request_locale
    AcceptLanguage.parse(request.headers.fetch("HTTP_ACCEPT_LANGUAGE")).match(*I18n.available_locales) if request.headers.key?("HTTP_ACCEPT_LANGUAGE")
  end
end
