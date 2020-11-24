import React from 'react';
import ReactSwipeableViews from 'react-swipeable-views';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import Video from 'mastodon/features/video';
import classNames from 'classnames';
import { defineMessages, injectIntl } from 'react-intl';
import IconButton from 'mastodon/components/icon_button';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ImageLoader from './image_loader';
import Icon from 'mastodon/components/icon';
import GIFV from 'mastodon/components/gifv';
import { disableSwiping } from 'mastodon/initial_state';
import Footer from 'mastodon/features/picture_in_picture/components/footer';

const messages = defineMessages({
  close: { id: 'lightbox.close', defaultMessage: 'Close' },
  previous: { id: 'lightbox.previous', defaultMessage: 'Previous' },
  next: { id: 'lightbox.next', defaultMessage: 'Next' },
});

export const previewState = 'previewMediaModal';

const digitCharacters = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z',
  '#',
  '$',
  '%',
  '*',
  '+',
  ',',
  '-',
  '.',
  ':',
  ';',
  '=',
  '?',
  '@',
  '[',
  ']',
  '^',
  '_',
  '{',
  '|',
  '}',
  '~',
];

const decode83 = (str) => {
  let value = 0;
  let c, digit;

  for (let i = 0; i < str.length; i++) {
    c = str[i];
    digit = digitCharacters.indexOf(c);
    value = value * 83 + digit;
  }

  return value;
};

const decodeRGB = int => ({
  r: Math.max(0, (int >> 16)),
  g: Math.max(0, (int >> 8) & 255),
  b: Math.max(0, (int & 255)),
});

export default @injectIntl
class MediaModal extends ImmutablePureComponent {

  static propTypes = {
    media: ImmutablePropTypes.list.isRequired,
    statusId: PropTypes.string,
    index: PropTypes.number.isRequired,
    onClose: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
    onChangeBackgroundColor: PropTypes.func.isRequired,
  };

  static contextTypes = {
    router: PropTypes.object,
  };

  state = {
    index: null,
    navigationHidden: false,
    zoomButtonHidden: false,
  };

  handleSwipe = (index) => {
    this.setState({ index: index % this.props.media.size });
  }

  handleTransitionEnd = () => {
    this.setState({
      zoomButtonHidden: false,
    });
  }

  handleNextClick = () => {
    this.setState({
      index: (this.getIndex() + 1) % this.props.media.size,
      zoomButtonHidden: true,
    });
  }

  handlePrevClick = () => {
    this.setState({
      index: (this.props.media.size + this.getIndex() - 1) % this.props.media.size,
      zoomButtonHidden: true,
    });
  }

  handleChangeIndex = (e) => {
    const index = Number(e.currentTarget.getAttribute('data-index'));

    this.setState({
      index: index % this.props.media.size,
      zoomButtonHidden: true,
    });
  }

  handleKeyDown = (e) => {
    switch(e.key) {
    case 'ArrowLeft':
      this.handlePrevClick();
      e.preventDefault();
      e.stopPropagation();
      break;
    case 'ArrowRight':
      this.handleNextClick();
      e.preventDefault();
      e.stopPropagation();
      break;
    }
  }

  componentDidMount () {
    window.addEventListener('keydown', this.handleKeyDown, false);

    if (this.context.router) {
      const history = this.context.router.history;

      history.push(history.location.pathname, previewState);

      this.unlistenHistory = history.listen(() => {
        this.props.onClose();
      });
    }

    this._sendBackgroundColor();
  }

  componentDidUpdate (prevProps, prevState) {
    if (prevState.index !== this.state.index) {
      this._sendBackgroundColor();
    }
  }

  _sendBackgroundColor () {
    const { media, onChangeBackgroundColor } = this.props;
    const index = this.getIndex();
    const backgroundColor = decodeRGB(decode83(media.getIn([index, 'blurhash']).slice(2, 6)));

    onChangeBackgroundColor(backgroundColor);
  }

  componentWillUnmount () {
    window.removeEventListener('keydown', this.handleKeyDown);

    if (this.context.router) {
      this.unlistenHistory();

      if (this.context.router.history.location.state === previewState) {
        this.context.router.history.goBack();
      }
    }

    this.props.onChangeBackgroundColor(null);
  }

  getIndex () {
    return this.state.index !== null ? this.state.index : this.props.index;
  }

  toggleNavigation = () => {
    this.setState(prevState => ({
      navigationHidden: !prevState.navigationHidden,
    }));
  };

  handleStatusClick = e => {
    if (e.button === 0 && !(e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      this.context.router.history.push(`/statuses/${this.props.statusId}`);
    }
  }

  render () {
    const { media, statusId, intl, onClose } = this.props;
    const { navigationHidden } = this.state;

    const index = this.getIndex();

    const leftNav  = media.size > 1 && <button tabIndex='0' className='media-modal__nav media-modal__nav--left' onClick={this.handlePrevClick} aria-label={intl.formatMessage(messages.previous)}><Icon id='chevron-left' fixedWidth /></button>;
    const rightNav = media.size > 1 && <button tabIndex='0' className='media-modal__nav  media-modal__nav--right' onClick={this.handleNextClick} aria-label={intl.formatMessage(messages.next)}><Icon id='chevron-right' fixedWidth /></button>;

    const content = media.map((image) => {
      const width  = image.getIn(['meta', 'original', 'width']) || null;
      const height = image.getIn(['meta', 'original', 'height']) || null;

      if (image.get('type') === 'image') {
        return (
          <ImageLoader
            previewSrc={image.get('preview_url')}
            src={image.get('url')}
            width={width}
            height={height}
            alt={image.get('description')}
            key={image.get('url')}
            onClick={this.toggleNavigation}
            zoomButtonHidden={this.state.zoomButtonHidden}
          />
        );
      } else if (image.get('type') === 'video') {
        const { time } = this.props;

        return (
          <Video
            preview={image.get('preview_url')}
            blurhash={image.get('blurhash')}
            src={image.get('url')}
            width={image.get('width')}
            height={image.get('height')}
            currentTime={time || 0}
            onCloseVideo={onClose}
            detailed
            alt={image.get('description')}
            key={image.get('url')}
          />
        );
      } else if (image.get('type') === 'gifv') {
        return (
          <GIFV
            src={image.get('url')}
            width={width}
            height={height}
            key={image.get('preview_url')}
            alt={image.get('description')}
            onClick={this.toggleNavigation}
          />
        );
      }

      return null;
    }).toArray();

    // you can't use 100vh, because the viewport height is taller
    // than the visible part of the document in some mobile
    // browsers when it's address bar is visible.
    // https://developers.google.com/web/updates/2016/12/url-bar-resizing
    const swipeableViewsStyle = {
      width: '100%',
      height: '100%',
    };

    const containerStyle = {
      alignItems: 'center', // center vertically
    };

    const navigationClassName = classNames('media-modal__navigation', {
      'media-modal__navigation--hidden': navigationHidden,
    });

    return (
      <div className='modal-root__modal media-modal'>
        <div className='media-modal__closer' role='presentation' onClick={onClose} >
          <ReactSwipeableViews
            style={swipeableViewsStyle}
            containerStyle={containerStyle}
            onChangeIndex={this.handleSwipe}
            onTransitionEnd={this.handleTransitionEnd}
            index={index}
            disabled={disableSwiping}
          >
            {content}
          </ReactSwipeableViews>
        </div>

        <div className={navigationClassName}>
          <IconButton className='media-modal__close' title={intl.formatMessage(messages.close)} icon='times' onClick={onClose} size={40} />

          {leftNav}
          {rightNav}

          <div className='media-modal__pagination'>
            {statusId && <Footer statusId={statusId} withOpenButton onClose={onClose} />}
          </div>
        </div>
      </div>
    );
  }

}
