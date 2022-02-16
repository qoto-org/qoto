import React from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';
import { FormattedMessage } from 'react-intl';
import Button from 'mastodon/components/button';
import classNames from 'classnames';

const mapStateToProps = state => ({
  rules: state.get('rules'),
});

export default @connect(mapStateToProps)
class Rules extends React.PureComponent {

  static propTypes = {
    onNextStep: PropTypes.func.isRequired,
    rules: ImmutablePropTypes.list,
    selectedRuleIds: ImmutablePropTypes.set.isRequired,
    onToggle: PropTypes.func.isRequired,
  };

  handleNextClick = () => {
    const { onNextStep } = this.props;
    onNextStep('statuses');
  };

  handleRulesChange = e => {
    const { onToggle } = this.props;
    onToggle(e.target.value, e.target.checked);
  };

  handleRulesKeyPress = e => {
    const { onToggle } = this.props;

    if (e.key === 'Enter' || e.key === ' ') {
      e.stopPropagation();
      e.preventDefault();

      onToggle(e.target.getAttribute('data-value'), e.target.getAttribute('aria-checked') === 'false');
    }
  }

  render () {
    const { rules, selectedRuleIds } = this.props;

    return (
      <div>
        <h3><FormattedMessage id='report.rules.title' defaultMessage='Which rules are being violated?' /></h3>
        <p><FormattedMessage id='report.rules.subtitle' defaultMessage='Select all that apply' /></p>

        {rules.map(item => (
          <label key={item.get('id')} className='poll__option selectable'>
            <input type='checkbox' name='rules' value={item.get('id')} checked={selectedRuleIds.includes(item.get('id'))} onChange={this.handleRulesChange} />

            <span
              className={classNames('poll__input checkbox', { active: selectedRuleIds.includes(item.get('id')) })}
              tabIndex='0'
              role='checkbox'
              onKeyPress={this.handleRulesKeyPress}
              aria-checked={selectedRuleIds.includes(item.get('id'))}
              aria-label={item.get('text')}
              data-value={item.get('id')}
            />

            <span className='poll__option__text'>{item.get('text')}</span>
          </label>
        ))}

        <Button onClick={this.handleNextClick}><FormattedMessage id='report.next' defaultMessage='Next' /></Button>
      </div>
    );
  }

}
