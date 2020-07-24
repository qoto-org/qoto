import { CRYPTO_INITIALIZE_SUCCESS } from 'mastodon/actions/crypto';
import { Map as ImmutableMap } from 'immutable';

const initialState = ImmutableMap({
  enabled: false,
});

export default function crypto (state = initialState, action) {
  switch(action.type) {
  case CRYPTO_INITIALIZE_SUCCESS:
    return state.set('enabled', action.account !== null);
  default:
    return state;
  }
};
