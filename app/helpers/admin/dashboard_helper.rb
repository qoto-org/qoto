# frozen_string_literal: true

module Admin::DashboardHelper
  def censored_email(str)
    first, last = str.split('@')

    censored_first = first.chars.map.with_index do |chr, i|
      if i > 0 && i < first.size - 1
        '*'
      else
        chr
      end
    end.join

    "#{censored_first}@#{last}"
  end

  def feature_hint(feature, enabled)
    indicator   = safe_join([enabled ? t('simple_form.yes') : t('simple_form.no'), fa_icon('power-off fw')], ' ')
    class_names = enabled ? 'pull-right positive-hint' : 'pull-right neutral-hint'

    safe_join([feature, content_tag(:span, indicator, class: class_names)])
  end
end
