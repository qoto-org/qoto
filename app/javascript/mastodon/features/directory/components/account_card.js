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
import Button from 'mastodon/components/button';
import { FormattedMessage, injectIntl, defineMessages } from 'react-intl';
import { autoPlayGif, me, unfollowModal } from 'mastodon/initial_state';
import ShortNumber from 'mastodon/components/short_number';
import {
  followAccount,
  unfollowAccount,
  blockAccount,
  unblockAccount,
  unmuteAccount,
} from 'mastodon/actions/accounts';
import { openModal } from 'mastodon/actions/modal';
import { initMuteModal } from 'mastodon/actions/mutes';
import classNames from 'classnames';

const messages = defineMessages({
  unfollow: { id: 'account.unfollow', defaultMessage: 'Unfollow' },
  follow: { id: 'account.follow', defaultMessage: 'Follow' },
  cancel_follow_request: { id: 'account.cancel_follow_request', defaultMessage: 'Cancel follow request' },
  requested: { id: 'account.requested', defaultMessage: 'Awaiting approval. Click to cancel follow request' },
  unblock: { id: 'account.unblock', defaultMessage: 'Unblock @{name}' },
  block: { id: 'account.block', defaultMessage: 'Block @{name}' },
});

const makeMapStateToProps = () => {
  const getAccount = makeGetAccount();

  const mapStateToProps = (state, { id }) => ({
    account: getAccount(state, id),
  });

  return mapStateToProps;
};

const mapDispatchToProps = (dispatch, { intl }) => ({
  onFollow(account) {
    if (
      account.getIn(['relationship', 'following']) ||
      account.getIn(['relationship', 'requested'])
    ) {
      if (unfollowModal) {
        dispatch(
          openModal('CONFIRM', {
            message: (
              <FormattedMessage
                id='confirmations.unfollow.message'
                defaultMessage='Are you sure you want to unfollow {name}?'
                values={{ name: <strong>@{account.get('acct')}</strong> }}
              />
            ),
            confirm: intl.formatMessage(messages.unfollowConfirm),
            onConfirm: () => dispatch(unfollowAccount(account.get('id'))),
          }),
        );
      } else {
        dispatch(unfollowAccount(account.get('id')));
      }
    } else {
      dispatch(followAccount(account.get('id')));
    }
  },

  onBlock(account) {
    if (account.getIn(['relationship', 'blocking'])) {
      dispatch(unblockAccount(account.get('id')));
    } else {
      dispatch(blockAccount(account.get('id')));
    }
  },

  onMute(account) {
    if (account.getIn(['relationship', 'muting'])) {
      dispatch(unmuteAccount(account.get('id')));
    } else {
      dispatch(initMuteModal(account));
    }
  },
});

export default
@injectIntl
@connect(makeMapStateToProps, mapDispatchToProps)
class AccountCard extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    intl: PropTypes.object.isRequired,
    onFollow: PropTypes.func.isRequired,
    onBlock: PropTypes.func.isRequired,
    onMute: PropTypes.func.isRequired,
  };

  handleMouseEnter = ({ currentTarget }) => {
    if (autoPlayGif) {
      return;
    }

    const emojis = currentTarget.querySelectorAll('.custom-emoji');

    for (var i = 0; i < emojis.length; i++) {
      let emoji = emojis[i];
      emoji.src = emoji.getAttribute('data-original');
    }
  }

  handleMouseLeave = ({ currentTarget }) => {
    if (autoPlayGif) {
      return;
    }

    const emojis = currentTarget.querySelectorAll('.custom-emoji');

    for (var i = 0; i < emojis.length; i++) {
      let emoji = emojis[i];
      emoji.src = emoji.getAttribute('data-static');
    }
  }

  handleFollow = () => {
    this.props.onFollow(this.props.account);
  };

  handleBlock = () => {
    this.props.onBlock(this.props.account);
  };

  handleMute = () => {
    this.props.onMute(this.props.account);
  };

  render() {
    const { account, intl } = this.props;

    let actionBtn;

    if (me !== account.get('id')) {
      if (!account.get('relationship')) { // Wait until the relationship is loaded
        actionBtn = '';
      } else if (account.getIn(['relationship', 'requested'])) {
        actionBtn = <Button className={classNames('logo-button')} text={intl.formatMessage(messages.cancel_follow_request)} title={intl.formatMessage(messages.requested)} onClick={this.handleFollow} />;
      } else if (!account.getIn(['relationship', 'blocking'])) {
        actionBtn = <Button disabled={account.getIn(['relationship', 'blocked_by'])} className={classNames('logo-button', { 'button--destructive': account.getIn(['relationship', 'following']) })} text={intl.formatMessage(account.getIn(['relationship', 'following']) ? messages.unfollow : messages.follow)} onClick={this.handleFollow} />;
      } else if (account.getIn(['relationship', 'blocking'])) {
        actionBtn = <Button className='logo-button' text={intl.formatMessage(messages.unblock, { name: account.get('username') })} onClick={this.handleBlock} />;
      }
    }

    return (
      <div className='account-card'>
        <Permalink href={account.get('url')} to={`/@${account.get('acct')}`} className='account-card__permalink'>
          <div className='account-card__header'>
            <img
              src={
                autoPlayGif ? account.get('header') : account.get('header_static')
              }
              alt=''
            />
          </div>

          <div className='account-card__title'>
            <div className='account-card__title__avatar'><Avatar account={account} size={56} /></div>
            <DisplayName account={account} />
          </div>
        </Permalink>

        {account.get('note').length > 0 && (
          <div
            className='account-card__bio translate'
            onMouseEnter={this.handleMouseEnter}
            onMouseLeave={this.handleMouseLeave}
            dangerouslySetInnerHTML={{ __html: account.get('note_emojified') }}
          />
        )}

        <div className='account-card__actions'>
          <div className='account-card__counters'>
            <div className='account-card__counters__item'>
              <ShortNumber value={account.get('statuses_count')} />
              <small>
                <FormattedMessage id='account.posts' defaultMessage='Toots' />
              </small>
            </div>

            <div className='account-card__counters__item'>
              <ShortNumber value={account.get('followers_count')} />{' '}
              <small>
                <FormattedMessage
                  id='account.followers'
                  defaultMessage='Followers'
                />
              </small>
            </div>

            <div className='account-card__counters__item'>
              <ShortNumber value={account.get('following_count')} />{' '}
              <small>
                <FormattedMessage
                  id='account.following'
                  defaultMessage='Following'
                />
              </small>
            </div>
          </div>

          <div className='account-card__actions__button'>
            {actionBtn}
          </div>
        </div>
      </div>
    );
  }

}
