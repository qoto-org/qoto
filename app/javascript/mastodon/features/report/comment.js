import React from 'react';
import PropTypes from 'prop-types';
import { injectIntl, defineMessages, FormattedMessage } from 'react-intl';
import Button from 'mastodon/components/button';

const messages = defineMessages({
  placeholder: { id: 'report.placeholder', defaultMessage: 'Type or paste additional comments' },
});

export default @injectIntl
class Comment extends React.PureComponent {

  static propTypes = {
    onSubmit: PropTypes.func.isRequired,
    comment: PropTypes.string.isRequired,
    onChangeComment: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
    isSubmitting: PropTypes.bool,
  };

  handleClick = () => {
    const { onSubmit } = this.props;
    onSubmit();
  };

  handleChange = e => {
    const { onChangeComment } = this.props;
    onChangeComment(e.target.value);
  };

  handleKeyDown = e => {
    if (e.keyCode === 13 && (e.ctrlKey || e.metaKey)) {
      this.handleClick();
    }
  };

  render () {
    const { comment, isSubmitting, intl } = this.props;

    return (
      <div>
        <h3><FormattedMessage id='report.comment.title' defaultMessage='Is there anything else you think we should know?' /></h3>

        <textarea
          className='setting-text light'
          placeholder={intl.formatMessage(messages.placeholder)}
          value={comment}
          onChange={this.handleChange}
          onKeyDown={this.handleKeyDown}
          disabled={isSubmitting}
        />

        <Button onClick={this.handleClick}><FormattedMessage id='report.submit' defaultMessage='Submit report' /></Button>
      </div>
    );
  }

}
