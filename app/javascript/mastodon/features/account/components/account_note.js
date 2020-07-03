import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import Textarea from 'react-textarea-autosize';
import { is } from 'immutable';

const messages = defineMessages({
  placeholder: { id: 'account_note.placeholder', defaultMessage: 'Click to add a note' },
});

export default @injectIntl
class Header extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    value: PropTypes.string,
    onSave: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
  };

  state = {
    value: '',
  };

  componentWillMount () {
    this._reset();
  }

  componentWillReceiveProps (nextProps) {
    if (!is(this.props.account, nextProps.account) || this.props.value !== nextProps.value) {
      this.setState({ value: nextProps.value || '' });
    }
  }

  componentWillUnmount () {
    if (this._isDirty()) {
      this._save();
    }
  }

  setTextareaRef = c => {
    this.textarea = c;
  }

  handleChange = e => {
    this.setState({ value: e.target.value });
  };

  handleKeyDown = e => {
    if (e.keyCode === 13 && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();

      this._save();

      if (this.textarea) {
        this.textarea.blur();
      }
    } else if (e.keyCode === 27) {
      e.preventDefault();

      this._reset(() => {
        if (this.textarea) {
          this.textarea.blur();
        }
      });
    }
  }

  handleBlur = () => {
    if (this._isDirty()) {
      this._save();
    }
  }

  _save () {
    this.props.onSave(this.state.value);
  }

  _reset (callback) {
    this.setState({ value: this.props.value || '' }, callback);
  }

  _isDirty () {
    return this.state.value !== this.props.value;
  }

  render () {
    const { account, intl } = this.props;
    const { value } = this.state;

    if (!account) {
      return null;
    }

    return (
      <div className='account__header__account-note'>
        <strong><FormattedMessage id='account.account_note_header' defaultMessage='Note' /></strong>

        <Textarea
          className='account__header__account-note__content'
          disabled={(typeof this.props.value === undefined)}
          placeholder={intl.formatMessage(messages.placeholder)}
          value={value}
          onChange={this.handleChange}
          onKeyDown={this.handleKeyDown}
          onBlur={this.handleBlur}
          ref={this.setTextareaRef}
        />
      </div>
    );
  }

}
