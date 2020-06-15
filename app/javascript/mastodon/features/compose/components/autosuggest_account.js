import React from 'react';
import Avatar from '../../../components/avatar';
import DisplayName from '../../../components/display_name';
import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import Tooltip from 'mastodon/components/tooltip';

export default class AutosuggestAccount extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
  };

  render () {
    const { account } = this.props;

    return (
      <Tooltip placement='top' overlay={account.get('acct')}>
        <div className='autosuggest-account'>
          <div className='autosuggest-account-icon'><Avatar account={account} size={18} /></div>
          <DisplayName account={account} />
        </div>
      </Tooltip>
    );
  }

}
