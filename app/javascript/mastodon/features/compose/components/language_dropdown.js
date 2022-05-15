import React from 'react';
import PropTypes from 'prop-types';
import { injectIntl, defineMessages } from 'react-intl';
import TextIconButton from './text_icon_button';
import Overlay from 'react-overlays/lib/Overlay';
import Motion from 'mastodon/features/ui/util/optional_motion';
import spring from 'react-motion/lib/spring';
import { supportsPassiveEvents } from 'detect-passive-events';
import classNames from 'classnames';
import { languages as preloadedLanguages } from 'mastodon/initial_state';
import fuzzysort from 'fuzzysort';

const messages = defineMessages({
  changeLanguage: { id: 'compose.language.change', defaultMessage: 'Change language' },
  search: { id: 'compose.language.search', defaultMessage: 'Search languages...' },
  clear: { id: 'emoji_button.clear', defaultMessage: 'Clear' },
});

// Copied from emoji-mart for consistency with emoji picker and since
// they don't export the icons in the package
const icons = {
  loupe: (
    <svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20' width='13' height='13'>
      <path d='M12.9 14.32a8 8 0 1 1 1.41-1.41l5.35 5.33-1.42 1.42-5.33-5.34zM8 14A6 6 0 1 0 8 2a6 6 0 0 0 0 12z' />
    </svg>
  ),

  delete: (
    <svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20' width='13' height='13'>
      <path d='M10 8.586L2.929 1.515 1.515 2.929 8.586 10l-7.071 7.071 1.414 1.414L10 11.414l7.071 7.071 1.414-1.414L11.414 10l7.071-7.071-1.414-1.414L10 8.586z' />
    </svg>
  ),
}

const listenerOptions = supportsPassiveEvents ? { passive: true } : false;

class LanguageDropdownMenu extends React.PureComponent {

  static propTypes = {
    style: PropTypes.object,
    value: PropTypes.string.isRequired,
    placement: PropTypes.string.isRequired,
    onClose: PropTypes.func.isRequired,
    onChange: PropTypes.func.isRequired,
    languages: PropTypes.arrayOf(PropTypes.arrayOf(PropTypes.string)),
    intl: PropTypes.object,
  };

  static defaultProps = {
    languages: preloadedLanguages,
  };

  state = {
    mounted: false,
    searchValue: '',
  };

  handleDocumentClick = e => {
    if (this.node && !this.node.contains(e.target)) {
      this.props.onClose();
    }
  }

  componentDidMount () {
    document.addEventListener('click', this.handleDocumentClick, false);
    document.addEventListener('touchend', this.handleDocumentClick, listenerOptions);
    this.setState({ mounted: true });
  }

  componentWillUnmount () {
    document.removeEventListener('click', this.handleDocumentClick, false);
    document.removeEventListener('touchend', this.handleDocumentClick, listenerOptions);
  }

  setRef = c => {
    this.node = c;
  }

  handleSearchChange = ({ target }) => {
    this.setState({ searchValue: target.value });
  }

  search () {
    const { languages, value } = this.props;
    const { searchValue } = this.state;

    if (searchValue === '') {
      return [...languages].sort((a, b) => {
         // Push current selection to the top of the list

        if (a[0] === value) {
          return -1;
        } else if (b[0] === value) {
          return 1;
        } else {
          return 0;
        }
      });
    }

    return fuzzysort.go(searchValue, languages, {
      keys: ['0', '1', '2'],
      limit: 5,
      threshold: -10000,
    }).map(result => result.obj);
  }

  frequentlyUsed () {
    const { languages, value } = this.props;
    const current = languages.find(lang => lang[0] === value);
    const results = [];

    if (current) {
      results.push(current);
    }

    return results;
  }

  handleClick = e => {
    const value = e.currentTarget.getAttribute('data-index');

    e.preventDefault();

    this.props.onClose();
    this.props.onChange(value);
  }

  handleKeyDown = e => {
    const results = this.search();
    const value = e.currentTarget.getAttribute('data-index');
    const index = results.findIndex(lang => lang[0] === value);

    let element = null;

    switch(e.key) {
    case 'Escape':
      this.props.onClose();
      break;
    case 'Enter':
      this.handleClick(e);
      break;
    case 'ArrowDown':
      element = this.node.childNodes[index + 1] || this.node.firstChild;
      break;
    case 'ArrowUp':
      element = this.node.childNodes[index - 1] || this.node.lastChild;
      break;
    case 'Tab':
      if (e.shiftKey) {
        element = this.node.childNodes[index - 1] || this.node.lastChild;
      } else {
        element = this.node.childNodes[index + 1] || this.node.firstChild;
      }
      break;
    case 'Home':
      element = this.node.firstChild;
      break;
    case 'End':
      element = this.node.lastChild;
      break;
    }

    if (element) {
      element.focus();
      this.props.onChange(element.getAttribute('data-index'));
      e.preventDefault();
      e.stopPropagation();
    }
  }

  handleClear = () => {
    this.setState({ searchValue: '' });
  }

  renderItem = lang => {
    const { value } = this.props;

    return (
      <div key={lang[0]} role='option' tabIndex='0' data-index={lang[0]} className={classNames('language-dropdown__dropdown__results__item', { active: lang[0] === value })} aria-selected={lang[0] === value} onClick={this.handleClick} onKeyDown={this.handleKeyDown}>
        <span className='language-dropdown__dropdown__results__item__native-name'>{lang[2]}</span> <span className='language-dropdown__dropdown__results__item__common-name'>({lang[1]})</span>
      </div>
    )
  }

  render () {
    const { style, placement, value, intl } = this.props;
    const { mounted, searchValue } = this.state;
    const isSearching = searchValue !== '';
    const results = this.search();

    return (
      <Motion defaultStyle={{ opacity: 0, scaleX: 0.85, scaleY: 0.75 }} style={{ opacity: spring(1, { damping: 35, stiffness: 400 }), scaleX: spring(1, { damping: 35, stiffness: 400 }), scaleY: spring(1, { damping: 35, stiffness: 400 }) }}>
        {({ opacity, scaleX, scaleY }) => (
          // It should not be transformed when mounting because the resulting
          // size will be used to determine the coordinate of the menu by
          // react-overlays
          <div className={`language-dropdown__dropdown ${placement}`} style={{ ...style, opacity: opacity, transform: mounted ? `scale(${scaleX}, ${scaleY})` : null }}>
            <div className='emoji-mart-search'>
              <input type='search' value={searchValue} onChange={this.handleSearchChange} placeholder={intl.formatMessage(messages.search)} autoFocus />
              <button className='emoji-mart-search-icon' disabled={!isSearching} aria-label={intl.formatMessage(messages.clear)} onClick={this.handleClear}>{!isSearching ? icons.loupe : icons.delete}</button>
            </div>

            <div className='language-dropdown__dropdown__results emoji-mart-scroll' role='listbox' ref={this.setRef}>
              {results.map(this.renderItem)}
            </div>
          </div>
        )}
      </Motion>
    );
  }

}

export default @injectIntl
class LanguageDropdown extends React.PureComponent {

  static propTypes = {
    value: PropTypes.string,
    intl: PropTypes.object.isRequired,
    onChange: PropTypes.func,
  };

  state = {
    open: false,
    placement: 'bottom',
  };

  handleToggle = ({ target }) => {
    const { top } = target.getBoundingClientRect();

    if (this.state.open && this.activeElement) {
      this.activeElement.focus({ preventScroll: true });
    }

    this.setState({ placement: top * 2 < innerHeight ? 'bottom' : 'top' });
    this.setState({ open: !this.state.open });
  }

  handleClose = () => {
    if (this.state.open && this.activeElement) {
      this.activeElement.focus({ preventScroll: true });
    }

    this.setState({ open: false });
  }

  handleChange = value => {
    const { onChange } = this.props;
    onChange(value);
  }

  render () {
    const { value, intl } = this.props;
    const { open, placement } = this.state;

    return (
      <div className={classNames('privacy-dropdown', { active: open })}>
        <div className='privacy-dropdown__value'>
          <TextIconButton
            className='privacy-dropdown__value-icon'
            label={value.toUpperCase()}
            title={intl.formatMessage(messages.changeLanguage)}
            active={open}
            onClick={this.handleToggle}
          />
        </div>

        <Overlay show={open} placement={placement} target={this}>
          <LanguageDropdownMenu
            value={value}
            onClose={this.handleClose}
            onChange={this.handleChange}
            placement={placement}
            intl={intl}
          />
        </Overlay>
      </div>
    );
  }

}
