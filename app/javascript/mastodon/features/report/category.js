import React from 'react';
import PropTypes from 'prop-types';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import Button from 'mastodon/components/button';
import classNames from 'classnames';

const messages = defineMessages({
  dislike: { id: 'report.reasons.dislike', defaultMessage: "I don't like it" },
  spam: { id: 'report.reasons.spam', defaultMessage: "It's spam" },
  violation: { id: 'report.reasons.violation', defaultMessage: 'It violates server rules' },
  other: { id: 'report.reasons.other', defaultMessage: "It's something else" },
});

export default @injectIntl
class Category extends React.PureComponent {

  static propTypes = {
    onNextStep: PropTypes.func.isRequired,
    category: PropTypes.string.isRequired,
    onChangeCategory: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
  };

  handleNextClick = () => {
    const { onNextStep, category } = this.props;

    if (category === 'violation') {
      onNextStep('rules');
    } else {
      onNextStep('statuses');
    }
  };

  handleCategoryChange = e => {
    const { onChangeCategory } = this.props;

    if (e.target.checked) {
      onChangeCategory(e.target.value);
    }
  };

  handleCategoryKeyPress = e => {
    const { onChangeCategory } = this.props;

    if (e.key === 'Enter' || e.key === ' ') {
      e.stopPropagation();
      e.preventDefault();

      onChangeCategory(e.target.getAttribute('data-value'));
    }
  }

  render () {
    const { category, intl } = this.props;

    const options = [
      'dislike',
      'spam',
      'violation',
      'other',
    ];

    return (
      <div>
        <h3><FormattedMessage id='report.category.title' defaultMessage="Tell us what's going on with this post" /></h3>
        <p><FormattedMessage id='report.category.subtitle' defaultMessage='Choose the best match' /></p>

        {options.map(item => (
          <label key={item} className='poll__option selectable'>
            <input type='radio' name='category' value={item} checked={category === item} onChange={this.handleCategoryChange} />

            <span
              className={classNames('poll__input', { active: category === item })}
              tabIndex='0'
              role='radio'
              onKeyPress={this.handleCategoryKeyPress}
              aria-checked={category === item}
              aria-label={intl.formatMessage(messages[item])}
              data-value={item}
            />

            <span className='poll__option__text'><strong>{intl.formatMessage(messages[item])}</strong></span>
          </label>
        ))}

        <Button onClick={this.handleNextClick}><FormattedMessage id='report.next' defaultMessage='Next' /></Button>
      </div>
    );
  }

}
