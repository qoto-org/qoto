import React from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';
import StatusCheckBox from 'mastodon/features/report/containers/status_check_box_container';
import { OrderedSet } from 'immutable';
import { FormattedMessage } from 'react-intl';
import Button from 'mastodon/components/button';

const mapStateToProps = (state, { accountId }) => ({
  availableStatusIds: OrderedSet(state.getIn(['timelines', `account:${accountId}:with_replies`, 'items'])),
});

export default @connect(mapStateToProps)
class Statuses extends React.PureComponent {

  static propTypes = {
    onNextStep: PropTypes.func.isRequired,
    accountId: PropTypes.string.isRequired,
    availableStatusIds: ImmutablePropTypes.set.isRequired,
    selectedStatusIds: ImmutablePropTypes.set.isRequired,
    onToggle: PropTypes.func.isRequired,
  };

  handleNextClick = () => {
    const { onNextStep } = this.props;
    onNextStep('comment');
  };

  render () {
    const { availableStatusIds, selectedStatusIds, onToggle } = this.props;

    return (
      <div>
        <h3><FormattedMessage id='report.statuses.title' defaultMessage='Are there any posts that back up this report?' /></h3>
        <p><FormattedMessage id='report.statuses.subtitle' defaultMessage='Select all that apply' /></p>

        <div className='report-modal__statuses'>
          <div>
            {availableStatusIds.union(selectedStatusIds).map(statusId => (
              <StatusCheckBox
                id={statusId}
                key={statusId}
                checked={selectedStatusIds.includes(statusId)}
                onToggle={onToggle}
              />
            ))}
          </div>
        </div>

        <Button onClick={this.handleNextClick}><FormattedMessage id='report.next' defaultMessage='Next' /></Button>
      </div>
    );
  }

}
