module ChallengableConcern
  extend ActiveSupport::Concern

  CHALLENGE_TIMEOUT = 1.hour.freeze

  def require_challenge!
    return if challenge_passed_recently?

    if params.key?(:form_challenge)
      if challenge_passed?
        session[:challenge_passed_at] = Time.now.utc
      else
        flash.now[:alert] = I18n.t('generic.challenge_not_passed')
        render template: 'auth/challenge', layout: 'auth'
      end
    else
      render template: 'auth/challenge', layout: 'auth'
    end
  end

  def challenge_passed?
    if current_user.encrypted_password.blank?
      current_account.username == challenge_params[:current_username]
    else
      current_user.valid_password?(challenge_params[:current_password])
    end
  end

  def challenge_passed_recently?
    session[:challenge_passed_at].present? && session[:challenge_passed_at] >= CHALLENGE_TIMEOUT.ago
  end

  def challenge_params
    params.require(:form_challenge).permit(:current_username, :current_password)
  end
end
