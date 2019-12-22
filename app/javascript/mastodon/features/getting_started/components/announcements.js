import React from 'react';
import ReactSwipeableViews from 'react-swipeable-views';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import IconButton from 'mastodon/components/icon_button';
import { FormattedDate } from 'react-intl';

export default class Announcements extends React.PureComponent {

  static propTypes = {
    announcements: ImmutablePropTypes.list,
    fetchAnnouncements: PropTypes.func.isRequired,
    domain: PropTypes.string.isRequired,
  };

  state = {
    index: 0,
  };

  componentDidMount () {
    const { fetchAnnouncements } = this.props;
    fetchAnnouncements();
  }

  handleChangeIndex = index => {
    this.setState({ index: index % this.props.announcements.size });
  }

  handleNextClick = () => {
    this.setState({ index: (this.state.index + 1) % this.props.announcements.size });
  }

  handlePrevClick = () => {
    this.setState({ index: (this.props.announcements.size + this.state.index - 1) % this.props.announcements.size });
  }

  renderAnnouncement (announcement) {
    const startsAt = new Date(announcement.get('starts_at'));
    const endsAt = new Date(announcement.get('ends_at'));
    const now = new Date();
    const skipYear = startsAt.getFullYear() === endsAt.getFullYear() && endsAt.getFullYear() === now.getFullYear();
    const skipEndDate = startsAt.getDate() === endsAt.getDate() && startsAt.getMonth() === endsAt.getMonth() && startsAt.getFullYear() === endsAt.getFullYear();

    return (
      <div key={announcement.get('id')} className='announcements__item'>
        <strong className='announcements__item__range'><FormattedDate value={startsAt} hour12={false} year={(skipYear || startsAt.getFullYear() === now.getFullYear()) ? undefined : 'numeric'} month='short' day='2-digit' hour='2-digit' minute='2-digit' /> - <FormattedDate value={endsAt} hour12={false} year={(skipYear || endsAt.getFullYear() === now.getFullYear()) ? undefined : 'numeric'} month={skipEndDate ? undefined : 'short'} day={skipEndDate ? undefined : '2-digit'} hour='2-digit' minute='2-digit' /></strong>
        <div dangerouslySetInnerHTML={{ __html: announcement.get('content') }} />
        <IconButton icon='times' className='announcements__item__dismiss-icon' />
      </div>
    );
  }

  render () {
    const { announcements, domain } = this.props;
    const { index } = this.state;

    if (announcements.isEmpty()) {
      return null;
    }

    return (
      <div className='announcements'>
        <ReactSwipeableViews index={index} onChangeIndex={this.handleChangeIndex}>
          {announcements.map(announcement => this.renderAnnouncement(announcement))}
        </ReactSwipeableViews>

        <div className='announcements__pagination'>
          <span className='announcements__pagination__domain'>{domain}</span>

          <IconButton icon='chevron-left' onClick={this.handlePrevClick} size={13} />
          <span>{index + 1} / {announcements.size}</span>
          <IconButton icon='chevron-right' onClick={this.handleNextClick} size={13} />
        </div>
      </div>
    );
  }

}
