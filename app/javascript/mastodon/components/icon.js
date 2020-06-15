import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import Tooltip from 'mastodon/components/tooltip';

export default class Icon extends React.PureComponent {

  static propTypes = {
    id: PropTypes.string.isRequired,
    className: PropTypes.string,
    title: PropTypes.node,
    fixedWidth: PropTypes.bool,
  };

  render () {
    const { id, className, fixedWidth, title, ...other } = this.props;

    return (
      <Tooltip placement='top' overlay={title}>
        <i role='img' className={classNames('fa', `fa-${id}`, className, { 'fa-fw': fixedWidth })} {...other} />
      </Tooltip>
    );
  }

}
