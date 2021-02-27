# frozen_string_literal: true

class BlacklistedEmailValidator < ActiveModel::Validator
  def validate(user)
    return if user.valid_invitation? || user.email.blank?

    @email = user.email

    user.errors.add(:email, :blocked_email_provider, message: I18n.t('users.blocked_email_provider')) if blocked_email?
  end

  private

  def blocked_email?
    on_blacklist? || not_on_whitelist?
  end

  def on_blacklist?
    return true  if EmailDomainBlock.block?(@email)
    return false if Rails.configuration.x.email_domains_blacklist.blank?

    domains = Rails.configuration.x.email_domains_blacklist.gsub('.', '\.')
    regexp  = Regexp.new("@(.+\\.)?(#{domains})", true)

    regexp.match?(@email)
  end

  def not_on_whitelist?
    return false if Rails.configuration.x.email_domains_whitelist.blank?

    domains = Rails.configuration.x.email_domains_whitelist.gsub('.', '\.')
    regexp  = Regexp.new("@(.+\\.)?(#{domains})$", true)

    @email !~ regexp
  end
end
