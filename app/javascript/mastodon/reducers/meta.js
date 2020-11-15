import { STORE_HYDRATE } from 'mastodon/actions/store';
import { APP_LAYOUT_CHANGE } from 'mastodon/actions/app';
import { Map as ImmutableMap } from 'immutable';
import { isMobile } from 'mastodon/is_mobile';
import { forceSingleColumn } from 'mastodon/initial_state';

const initialState = ImmutableMap({
  streaming_api_base_url: null,
  access_token: null,
  layout: isMobile(window.innerWidth) ? 'mobile' : (forceSingleColumn ? 'single-column' : 'multi-column'),
});

export default function meta(state = initialState, action) {
  switch(action.type) {
  case STORE_HYDRATE:
    return state.merge(action.state.get('meta'));
  case APP_LAYOUT_CHANGE:
    return state.set('layout', action.layout);
  default:
    return state;
  }
};
