import React from 'react';
import PropTypes from 'prop-types';
import Tooltip from 'rc-tooltip';

const OptionalTooltip = ({ overlay, children, ...other }) => {
  if (overlay) {
    return (
      <Tooltip animation='zoom' mouseEnterDelay={0.2} destroyTooltipOnHide {...other} overlay={overlay}>
        {children}
      </Tooltip>
    );
  } else {
    return children;
  }
};

OptionalTooltip.propTypes = {
  children: PropTypes.node,
  overlay: PropTypes.node,
};

export default OptionalTooltip;
