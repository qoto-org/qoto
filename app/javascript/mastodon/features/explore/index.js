import React from 'react';
import { connect } from 'react-redux';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import Column from 'mastodon/components/column';
import ColumnHeader from 'mastodon/components/column_header';
import { addColumn, removeColumn, moveColumn, changeColumnParams } from 'mastodon/actions/columns';
import classNames from 'classnames';
import SwipeableViews from 'react-swipeable-views';
import Hashtag, { ImmutableHashtag } from 'mastodon/components/hashtag';
import Story from './components/story';
import { fetchTrendingHashtags, fetchTrendingLinks } from 'mastodon/actions/trends';

const messages = defineMessages({
  title: { id: 'explore.title', defaultMessage: 'Explore' },
});

const mapStateToProps = state => ({
  hashtags: state.getIn(['trends', 'tags', 'items']),
  isLoadingHashtags: state.getIn(['trends', 'tags', 'isLoading']),
  links: state.getIn(['trends', 'links', 'items']),
  isLoadingLinks: state.getIn(['trends', 'links', 'isLoading']),
});

export default @connect(mapStateToProps)
@injectIntl
class Explore extends React.PureComponent {

  static contextTypes = {
    router: PropTypes.object,
  };

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    columnId: PropTypes.string,
    intl: PropTypes.object.isRequired,
    multiColumn: PropTypes.bool,
    hashtags: ImmutablePropTypes.list,
    links: ImmutablePropTypes.list,
  };

  state = {
    index: 0,
  };

  handleChange = (_, value) => {
    this.setState({ index: value });
  }

  handleChangeIndex = ({ currentTarget }) => {
    this.setState({ index: Number(currentTarget.getAttribute('data-index')) });
  }

  handlePin = () => {
    const { columnId, dispatch } = this.props;

    if (columnId) {
      dispatch(removeColumn(columnId));
    } else {
      dispatch(addColumn('EXPLORE'));
    }
  }

  handleMove = dir => {
    const { columnId, dispatch } = this.props;
    dispatch(moveColumn(columnId, dir));
  }

  handleHeaderClick = () => {
    this.column.scrollTop();
  }

  componentDidMount () {
    const { dispatch } = this.props;

    dispatch(fetchTrendingHashtags());
    dispatch(fetchTrendingLinks());
  }

  setRef = c => {
    this.column = c;
  }

  render () {
    const { intl, columnId, multiColumn, hashtags, isLoadingHashtags, links, isLoadingLinks } = this.props;
    const { index } = this.state;

    return (
      <Column bindToDocument={!multiColumn} ref={this.setRef} label={intl.formatMessage(messages.title)}>
        <ColumnHeader
          icon='globe'
          title={intl.formatMessage(messages.title)}
          onPin={this.handlePin}
          onMove={this.handleMove}
          onClick={this.handleHeaderClick}
          pinned={!!columnId}
          multiColumn={multiColumn}
        />

        <div className='scrollable'>
          <div className='account__section-headline'>
            <button className={classNames({ active: index === 0 })} data-index={0} onClick={this.handleChangeIndex}><FormattedMessage id='explore.trending_tags' defaultMessage='Trending hashtags' /></button>
            <button className={classNames({ active: index === 1 })} data-index={1} onClick={this.handleChangeIndex}><FormattedMessage id='explore.trending_links' defaultMessage='Top stories' /></button>
          </div>

          <SwipeableViews index={index} onChangeIndex={this.handleChangeIndex}>
            <div className='explore__tags'>
              {isLoadingHashtags ? (Array.from(Array(10)).map((_, i) => <Hashtag key={i} />)) : hashtags.map(hashtag => (
                <ImmutableHashtag key={hashtag.get('name')} hashtag={hashtag} />
              ))}
            </div>

            <div className='explore__links'>
              {isLoadingLinks ? (Array.from(Array(5)).map((_, i) => <Story key={i} />)) : links.map(link => (
                <Story
                  key={link.get('id')}
                  url={link.get('url')}
                  title={link.get('title')}
                  publisher={link.get('provider_name')}
                  sharedTimes={link.getIn(['history', 0, 'accounts']) * 1 + link.getIn(['history', 1, 'accounts']) * 1}
                  thumbnail={link.get('image')}
                  blurhash={link.get('blurhash')}
                />
              ))}
            </div>
          </SwipeableViews>
        </div>
      </Column>
    );
  }

}
