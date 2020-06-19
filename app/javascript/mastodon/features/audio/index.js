import React from 'react';
import PropTypes from 'prop-types';
import WaveSurfer from 'wavesurfer.js';
import { defineMessages, injectIntl } from 'react-intl';
import { formatTime } from 'mastodon/features/video';
import Icon from 'mastodon/components/icon';
import classNames from 'classnames';
import { throttle } from 'lodash';
import { encode, decode } from 'blurhash';

const digitCharacters = [
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
  "#",
  "$",
  "%",
  "*",
  "+",
  ",",
  "-",
  ".",
  ":",
  ";",
  "=",
  "?",
  "@",
  "[",
  "]",
  "^",
  "_",
  "{",
  "|",
  "}",
  "~"
];

const decode83 = (str) => {
  let value = 0;
  for (let i = 0; i < str.length; i++) {
    const c = str[i];
    const digit = digitCharacters.indexOf(c);
    value = value * 83 + digit;
  }
  return value;
};

const messages = defineMessages({
  play: { id: 'video.play', defaultMessage: 'Play' },
  pause: { id: 'video.pause', defaultMessage: 'Pause' },
  mute: { id: 'video.mute', defaultMessage: 'Mute sound' },
  unmute: { id: 'video.unmute', defaultMessage: 'Unmute sound' },
  download: { id: 'video.download', defaultMessage: 'Download file' },
});

const TICK_SIZE = 10;
const PADDING = 180;

export default @injectIntl
class Audio extends React.PureComponent {

  static propTypes = {
    src: PropTypes.string.isRequired,
    alt: PropTypes.string,
    poster: PropTypes.string,
    duration: PropTypes.number,
    peaks: PropTypes.arrayOf(PropTypes.number),
    height: PropTypes.number,
    preload: PropTypes.bool,
    editable: PropTypes.bool,
    intl: PropTypes.object.isRequired,
  };

  state = {
    currentTime: 0,
    duration: null,
    paused: true,
    muted: false,
    volume: 0.5,
    containerWidth: 0,
    color: { r: 255, g: 255, b: 255 },
  };

  // Hard coded in components.scss
  // Any way to get ::before values programatically?
  volWidth  = 50;
  volOffset = 70;

  volHandleOffset = v => {
    const offset = v * this.volWidth + this.volOffset;

    return (offset > 110) ? 110 : offset;
  }

  setPlayerRef = c => {
    this.player = c;

    if (c) {
      const width  = c.offsetWidth;
      const height = width / (16/9);

      this.setState({ width, height });
    }
  }

  setVolumeRef = c => {
    this.volume = c;
  }

  setAudioRef = c => {
    this.audio = c;

    if (this.audio) {
      this.setState({ volume: this.audio.volume, muted: this.audio.muted });
    }
  }

  setBlurhashCanvasRef = c => {
    this.blurhashCanvas = c;
  }

  setCanvasRef = c => {
    this.canvas = c;

    if (c) {
      this.canvasContext = c.getContext('2d');
    }
  }

  componentDidMount () {
    window.addEventListener('scroll', this.handleScroll);

    const img = new Image();
    img.onload = () => this.handlePosterLoad(img);
    img.src = this.props.poster;
  }

  componentDidUpdate (prevProps, prevState) {
    if (prevProps.poster !== this.props.poster) {
      const img = new Image();
      img.onload = () => this.handlePosterLoad(img);
      img.src = this.props.poster;
    }

    if (prevState.blurhash !== this.state.blurhash) {
      const context = this.blurhashCanvas.getContext('2d');
      const pixels = decode(this.state.blurhash, 32, 32);
      const outputImageData = new ImageData(pixels, 32, 32);

      context.putImageData(outputImageData, 0, 0);
    }

    this._clear();
    this._draw();
  }

  componentWillUnmount () {
    window.removeEventListener('scroll', this.handleScroll);
  }

  togglePlay = () => {
    if (this.state.paused) {
      this.setState({ paused: false }, () => this.audio.play());
    } else {
      this.setState({ paused: true }, () => this.audio.pause());
    }
  }

  handlePlay = () => {
    this.setState({ paused: false });

    if (this.canvas) {
      this._initAudioContext();
    }

    if (this.audioContext && this.audioContext.state === 'suspended') {
      this.audioContext.resume();
    }

    this._renderCanvas();
  }

  handlePause = () => {
    this.setState({ paused: true });
  }

  toggleMute = () => {
    const muted = !this.state.muted;

    this.setState({ muted }, () => {
      this.audio.muted = muted;
    });
  }

  handleVolumeMouseDown = e => {
    document.addEventListener('mousemove', this.handleMouseVolSlide, true);
    document.addEventListener('mouseup', this.handleVolumeMouseUp, true);
    document.addEventListener('touchmove', this.handleMouseVolSlide, true);
    document.addEventListener('touchend', this.handleVolumeMouseUp, true);

    this.handleMouseVolSlide(e);

    e.preventDefault();
    e.stopPropagation();
  }

  handleVolumeMouseUp = () => {
    document.removeEventListener('mousemove', this.handleMouseVolSlide, true);
    document.removeEventListener('mouseup', this.handleVolumeMouseUp, true);
    document.removeEventListener('touchmove', this.handleMouseVolSlide, true);
    document.removeEventListener('touchend', this.handleVolumeMouseUp, true);
  }

  handleTimeUpdate = () => {
    this.setState({
      currentTime: Math.floor(this.audio.currentTime),
      duration: Math.floor(this.audio.duration),
    });
  }

  handleMouseVolSlide = throttle(e => {
    const rect = this.volume.getBoundingClientRect();
    const x    = (e.clientX - rect.left) / this.volWidth; // x position within the element.

    if(!isNaN(x)) {
      let slideamt = x;

      if (x > 1) {
        slideamt = 1;
      } else if(x < 0) {
        slideamt = 0;
      }

      this.setState({ volume: slideamt }, () => {
        this.audio.volume = slideamt;
      });
    }
  }, 60);

  handleScroll = throttle(() => {
    return;

    if (!this.canvas || !this.audio) {
      return;
    }

    const { top, height } = this.canvas.getBoundingClientRect();
    const inView = (top <= (window.innerHeight || document.documentElement.clientHeight)) && (top + height >= 0);

    if (!this.state.paused && !inView) {
      this.setState({ paused: true }, () => this.audio.pause());
    }
  }, 150, { trailing: true });

  _initAudioContext () {
    const context  = new AudioContext();
    const analyser = context.createAnalyser();    
    const source   = context.createMediaElementSource(this.audio);

    analyser.smoothingTimeConstant = 0.6;
    analyser.fftSize = 2048;

    source.connect(analyser);
    source.connect(context.destination);

    this.audioContext = context;
    this.analyser = analyser;
  }

  handlePosterLoad = image => {
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');

    canvas.width  = image.width;
    canvas.height = image.height;

    context.drawImage(image, 0, 0);

    const inputImageData = context.getImageData(0, 0, image.width, image.height);
    const blurhash = encode(inputImageData.data, image.width, image.height, 4, 4);
    const averageColor = decode83(blurhash.slice(2, 6));

    this.setState({
      blurhash,

      color: {
        r: Math.max(0, (averageColor >> 16) - 80),
        g: Math.max(0, ((averageColor >> 8) & 255) - 80),
        b: Math.max(0, (averageColor & 255) - 80),
      },
    });
  }

  _renderCanvas () {
    requestAnimationFrame(() => {
      this._clear();
      this._draw();

      if (!this.state.paused) {
        this._renderCanvas();
      }
    });
  }

  _clear () {
    this.canvasContext.clearRect(0, 0, this.state.width, this.state.height);
  }

  _draw () {
    this.canvasContext.save();

    const [ticks, scale] = this._getTicks(360 * this._getScaleCoefficient(), TICK_SIZE);

    ticks.forEach(tick => {
      this._drawTick(tick.x1, tick.y1, tick.x2, tick.y2);
    });

    this.canvasContext.restore();
  }

  _getRadius () {
    return ((this.state.height || this.props.height) - (PADDING * this._getScaleCoefficient()) * 2) / 2;
  }

  _getScaleCoefficient () {
    return (this.state.height || this.props.height) / 982;
  }

  _getTicks (count, size, animationParams = [0, 90]) {
    const radius = this._getRadius();
    const ticks = this._getTickPoints(count);
    const lesser = 200;
    const m = [];
    const bufferLength = this.analyser ? this.analyser.frequencyBinCount : 0;
    const frequencyData = new Uint8Array(bufferLength);
    const allScales = [];
    const scaleCoefficient = this._getScaleCoefficient();

    if (this.analyser) {
      this.analyser.getByteFrequencyData(frequencyData);
    }

    ticks.forEach((tick, i) => {
      const coef = 1 - i / (ticks.length * 2.5);

      let delta = ((frequencyData[i] || 0) - lesser * coef) * scaleCoefficient;

      if (delta < 0) {
        delta = 0;
      }

      let k;

      if (animationParams[0] <= tick.angle && tick.angle <= animationParams[1]) {
        k = radius / (radius - this._getSize(tick.angle, animationParams[0], animationParams[1]) - delta);
      } else {
        k = radius / (radius - (size + delta));
      }

      const x1 = tick.x * (radius - size);
      const y1 = tick.y * (radius - size);
      const x2 = x1 * k;
      const y2 = y1 * k;

      m.push({ x1, y1, x2, y2 });

      if (i < 20) {
        let scale = delta / (200 * scaleCoefficient);
        scale = scale < 1 ? 1 : scale;
        allScales.push(scale);
      }
    });

    const sum = allScales.reduce((pv, cv) => pv + cv, 0) / allScales.length;

    return [m.map(({ x1, y1, x2, y2 }) => ({
      x1: x1,
      y1: y1,
      x2: x2 * sum,
      y2: y2 * sum,
    })), sum];
  }

  _getSize (angle, l, r) {
    const scaleCoefficient = this._getScaleCoefficient();
    const maxTickSize = TICK_SIZE * 9 * scaleCoefficient;
    const m = (r - l) / 2;
    const x = (angle - l);

    let h;

    if (x == m) {
      return maxTickSize;
    }

    const d = Math.abs(m - x);
    const v = 40 * Math.sqrt(1 / d);

    if (v > maxTickSize) {
      h = maxTickSize;
    } else {
      h = Math.max(TICK_SIZE, v);
    }

    return h;
  }

  _getTickPoints (count) {
    const PI = 360;
    const coords = [];
    const step = PI / count;

    let rad;

    for(let deg = 0; deg < PI; deg += step) {
      rad = deg * Math.PI / (PI / 2);
      coords.push({ x: Math.cos(rad), y: -Math.sin(rad), angle: deg });
    }

    return coords;
  }

  _drawTick (x1, y1, x2, y2) {
    const radius = this._getRadius();
    const cx = this.state.width / 2;
    const cy = radius + (PADDING * this._getScaleCoefficient());

    const dx1 = parseInt(cx + x1);
    const dy1 = parseInt(cy + y1);
    const dx2 = parseInt(cx + x2);
    const dy2 = parseInt(cy + y2);

    const gradient = this.canvasContext.createLinearGradient(dx1, dy1, dx2, dy2);
    
    const mainColor = `rgb(${this.state.color.r}, ${this.state.color.g}, ${this.state.color.b})`;
    const lastColor = `rgba(${this.state.color.r}, ${this.state.color.g}, ${this.state.color.b}, 0)`;

    gradient.addColorStop(0, mainColor);
    gradient.addColorStop(0.6, mainColor);
    gradient.addColorStop(1, lastColor);

    this.canvasContext.beginPath();
    this.canvasContext.strokeStyle = gradient;
    this.canvasContext.lineWidth = 2;
    this.canvasContext.moveTo(dx1, dy1);
    this.canvasContext.lineTo(dx2, dy2);
    this.canvasContext.stroke();
  }

  _getColor () {
    return `rgb(${this.state.color.r}, ${this.state.color.g}, ${this.state.color.b})`;
  }

  render () {
    const { src, intl, alt, editable } = this.props;
    const { paused, muted, volume, currentTime } = this.state;

    const volumeWidth     = muted ? 0 : volume * this.volWidth;
    const volumeHandleLoc = muted ? this.volHandleOffset(0) : this.volHandleOffset(volume);

    return (
      <div className={classNames('audio-player', { editable })} ref={this.setPlayerRef} style={{ width: this.state.width || '100%', height: this.state.height || this.props.height }}>
        <audio
          src={src}
          ref={this.setAudioRef}
          preload='none'
          onPlay={this.handlePlay}
          onPause={this.handlePause}
          onTimeUpdate={this.handleTimeUpdate}
        />

        <canvas 
          className='audio-player__background'
          width='32'
          height='32'
          style={{ width: this.state.width, height: this.state.height, position: 'absolute', top: 0, left: 0 }}
          ref={this.setBlurhashCanvasRef}
        />

        <canvas
          className='audio-player__canvas'
          aria-label={alt}
          title={alt}
          width={this.state.width}
          height={this.state.height}
          style={{ width: '100%', position: 'absolute', top: 0, left: 0 }}
          ref={this.setCanvasRef}
        />

        <img
          src={this.props.poster}
          width={(this._getRadius() - TICK_SIZE) * 2}
          height={(this._getRadius() - TICK_SIZE) * 2}
          style={{ position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)', borderRadius: '50%' }}
        />

        <div className='video-player__controls active'>
          <div className='video-player__buttons-bar'>
            <div className='video-player__buttons left'>
              <button type='button' title={intl.formatMessage(paused ? messages.play : messages.pause)} aria-label={intl.formatMessage(paused ? messages.play : messages.pause)} onClick={this.togglePlay}><Icon id={paused ? 'play' : 'pause'} fixedWidth /></button>
              <button type='button' title={intl.formatMessage(muted ? messages.unmute : messages.mute)} aria-label={intl.formatMessage(muted ? messages.unmute : messages.mute)} onClick={this.toggleMute}><Icon id={muted ? 'volume-off' : 'volume-up'} fixedWidth /></button>

              <div className='video-player__volume' onMouseDown={this.handleVolumeMouseDown} ref={this.setVolumeRef}>
                &nbsp;
                <div className='video-player__volume__current' style={{ width: `${volumeWidth}px`, backgroundColor: this._getColor() }} />

                <span
                  className={classNames('video-player__volume__handle')}
                  tabIndex='0'
                  style={{ left: `${volumeHandleLoc}px`, backgroundColor: this._getColor() }}
                />
              </div>

              <span>
                <span className='video-player__time-current'>{formatTime(currentTime)}</span>
                <span className='video-player__time-sep'>/</span>
                <span className='video-player__time-total'>{formatTime(this.state.duration || Math.floor(this.props.duration))}</span>
              </span>
            </div>

            <div className='video-player__buttons right'>
              <button type='button' title={intl.formatMessage(messages.download)} aria-label={intl.formatMessage(messages.download)}>
                <a className='video-player__download__icon' href={this.props.src} download>
                  <Icon id='download' fixedWidth />
                </a>
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

}
