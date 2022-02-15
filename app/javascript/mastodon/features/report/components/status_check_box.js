import React from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import Toggle from 'react-toggle';
import noop from 'lodash/noop';
import StatusContent from 'mastodon/components/status_content';
import { MediaGallery, Video } from 'mastodon/features/ui/util/async-components';
import Bundle from 'mastodon/features/ui/components/bundle';

export default class StatusCheckBox extends React.PureComponent {

  static propTypes = {
    id: PropTypes.string.isRequired,
    status: ImmutablePropTypes.map.isRequired,
    checked: PropTypes.bool,
    onToggle: PropTypes.func.isRequired,
    disabled: PropTypes.bool,
  };

  handleToggle = (e) => {
    const { onToggle, id } = this.props;
    onToggle(id, e.target.checked);
  };

  render () {
    const { status, checked, disabled } = this.props;

    let media = null;

    if (status.get('reblog')) {
      return null;
    }

    if (status.get('media_attachments').size > 0) {
      if (status.get('media_attachments').some(item => item.get('type') === 'unknown')) {

      } else if (status.getIn(['media_attachments', 0, 'type']) === 'video') {
        const video = status.getIn(['media_attachments', 0]);

        media = (
          <Bundle fetchComponent={Video} loading={this.renderLoadingVideoPlayer} >
            {Component => (
              <Component
                preview={video.get('preview_url')}
                blurhash={video.get('blurhash')}
                src={video.get('url')}
                alt={video.get('description')}
                width={239}
                height={110}
                inline
                sensitive={status.get('sensitive')}
                onOpenVideo={noop}
              />
            )}
          </Bundle>
        );
      } else {
        media = (
          <Bundle fetchComponent={MediaGallery} loading={this.renderLoadingMediaGallery} >
            {Component => <Component media={status.get('media_attachments')} sensitive={status.get('sensitive')} height={110} onOpenMedia={noop} />}
          </Bundle>
        );
      }
    }

    return (
      <div className='status-check-box'>
        <div className='status-check-box__status'>
          <StatusContent status={status} />
          {media}
        </div>

        <div className='status-check-box-toggle'>
          <Toggle checked={checked} onChange={this.handleToggle} disabled={disabled} />
        </div>
      </div>
    );
  }

}
