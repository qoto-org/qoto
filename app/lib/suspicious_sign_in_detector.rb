# frozen_string_literal: true

class SuspiciousSignInDetector
  IP_TOLERANCE_MASK = 64

  def initialize(user, request)
    @user = user
  end

  def suspicious?(request)
    !(sufficient_security_measures? || freshly_signed_up? || previously_seen_ip?(masked_ip(request)))
  end

  private

  def sufficient_security_measures?
    @user.otp_required_for_login?
  end

  def previously_seen_ip?(ip)
    @user.ips.where('ip << ?', ip).exists?
  end

  def freshly_signed_up?
    @user.current_sign_in_at.blank?
  end

  def masked_ip(request)
    IPAddr.new(request.remote_ip).mask(IP_TOLERANCE_MASK).to_s
  end
end
