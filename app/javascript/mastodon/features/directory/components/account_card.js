import React from 'react';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { makeGetAccount } from 'mastodon/selectors';
import Avatar from 'mastodon/components/avatar';
import DisplayName from 'mastodon/components/display_name';
import Permalink from 'mastodon/components/permalink';
import RelativeTimestamp from 'mastodon/components/relative_timestamp';
import IconButton from 'mastodon/components/icon_button';
import { FormattedMessage, injectIntl, defineMessages } from 'react-intl';
import { me } from 'mastodon/initial_state';
import { shortNumberFormat } from 'mastodon/utils/numbers';

const messages = defineMessages({
  follow: { id: 'account.follow', defaultMessage: 'Follow' },
  unfollow: { id: 'account.unfollow', defaultMessage: 'Unfollow' },
  requested: { id: 'account.requested', defaultMessage: 'Awaiting approval' },
  unblock: { id: 'account.unblock', defaultMessage: 'Unblock @{name}' },
  unmute: { id: 'account.unmute', defaultMessage: 'Unmute @{name}' },
});

const makeMapStateToProps = () => {
  const getAccount = makeGetAccount();

  const mapStateToProps = (state, { id }) => ({
    account: getAccount(state, id),
  });

  return mapStateToProps;
};

export default @connect(makeMapStateToProps)
@injectIntl
class AccountCard extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    intl: PropTypes.object.isRequired,
  };

  render () {
    const { account, intl } = this.props;

    let buttons;

    if (account.get('id') !== me && account.get('relationship', null) !== null) {
      const following = account.getIn(['relationship', 'following']);
      const requested = account.getIn(['relationship', 'requested']);
      const blocking  = account.getIn(['relationship', 'blocking']);
      const muting    = account.getIn(['relationship', 'muting']);

      if (requested) {
        buttons = <IconButton disabled icon='hourglass' title={intl.formatMessage(messages.requested)} />;
      } else if (blocking) {
        buttons = <IconButton active icon='unlock' title={intl.formatMessage(messages.unblock, { name: account.get('username') })} onClick={this.handleBlock} />;
      } else if (muting) {
        buttons = <IconButton active icon='volume-up' title={intl.formatMessage(messages.unmute, { name: account.get('username') })} onClick={this.handleMute} />;
      } else if (!account.get('moved') || following) {
        buttons = <IconButton icon={following ? 'user-times' : 'user-plus'} title={intl.formatMessage(following ? messages.unfollow : messages.follow)} onClick={this.handleFollow} active={following} />;
      }
    }

    return (
      <div className='directory__card'>
        <div className='directory__card__img'>
          <img src={account.get('header')} alt='' />
        </div>

        <div className='directory__card__bar'>
          <Permalink className='directory__card__bar__name' href={account.get('url')} to={`/accounts/${account.get('id')}`}>
            <Avatar account={account} size={48} />
            <DisplayName account={account} />
          </Permalink>

          <div className='directory__card__bar__relationship account__relationship'>
            {buttons}
          </div>
        </div>

        <div className='directory__card__extra'>
          <div className='accounts-table__count'>{shortNumberFormat(account.get('statuses_count'))} <small><FormattedMessage id='account.posts' defaultMessage='Toots' /></small></div>
          <div className='accounts-table__count'>{shortNumberFormat(account.get('followers_count'))} <small><FormattedMessage id='account.followers' defaultMessage='Followers' /></small></div>
          <div className='accounts-table__count'>{account.get('last_status_at') === null ? <FormattedMessage id='account.never_active' defaultMessage='Never' /> : <RelativeTimestamp timestamp={account.get('last_status_at')} />} <small><FormattedMessage id='account.last_status' defaultMessage='Last active' /></small></div>
        </div>
      </div>
    );
  }

}
