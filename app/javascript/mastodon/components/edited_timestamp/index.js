import React from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { FormattedMessage, injectIntl } from 'react-intl';
import Icon from 'mastodon/components/icon';
import DropdownMenu from './containers/dropdown_menu_container';
import { connect } from 'react-redux';
import classNames from 'classnames';
import RelativeTimestamp from 'mastodon/components/relative_timestamp';
import AccountName from 'mastodon/components/account_name';

export default @injectIntl
class EditedTimestamp extends React.PureComponent {

  static propTypes = {
    statusId: PropTypes.string.isRequired,
    accountId: PropTypes.string.isRequired,
    timestamp: PropTypes.string.isRequired,
    intl: PropTypes.object.isRequired,
  };

  renderHeader = items => {
    return (
      <FormattedMessage id='status.edited_x_times' defaultMessage='Edited {count, plural, one {{count} time} other {{count} times}}' values={{ count: items.size - 1 }} />
    )
  }

  renderItem = (item, index, { setFocusRef }) => {
    const { intl, accountId } = this.props;
    const formattedDate = <RelativeTimestamp timestamp={item.get('created_at')} short={false} />;
    const formattedName = <AccountName accountId={accountId} />;

    const element = item.get('original') ? (
      <FormattedMessage id='status.created' defaultMessage='{name} created {date}' values={{ name: formattedName, date: formattedDate }} />
    ) : (
      <button data-index={index} ref={index === 0 ? setFocusRef : null}><FormattedMessage id='status.detailed_edited' defaultMessage='{name} edited {date}' values={{ name: formattedName, date: formattedDate }} /></button>
    );

    return (
      <li className={classNames('dropdown-menu__item', { 'dropdown-menu__item--text': item.get('original') })} key={item.get('created_at')}>
        {element}
      </li>
    )
  }

  render () {
    const { timestamp, intl, statusId } = this.props;

    return (
      <DropdownMenu statusId={statusId} renderItem={this.renderItem} scrollable renderHeader={this.renderHeader}>
        <button className='dropdown-menu__text-button'>
          <FormattedMessage id='status.edited' defaultMessage='Edited {date}' values={{ date: intl.formatDate(timestamp, { hour12: false, month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' }) }} /> <Icon id='caret-down' />
        </button>
      </DropdownMenu>
    );
  }

}
