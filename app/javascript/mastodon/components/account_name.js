import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';
import { makeGetAccount } from 'mastodon/selectors';
import Avatar from 'mastodon/components/avatar';

const makeMapStateToProps = () => {
  const getAccount = makeGetAccount();

  const mapStateToProps = (state, { accountId }) => ({
    account: getAccount(state, accountId),
  });

  return mapStateToProps;
};

export default @connect(makeMapStateToProps)
class AccountName extends React.PureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
  };

  render () {
    const { account } = this.props;

    return (
      <span className='account-name'><Avatar size={13} account={account} /> <strong>{account.get('username')}</strong></span>
    );
  }

}
