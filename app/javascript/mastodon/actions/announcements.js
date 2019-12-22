import api from '../api';

export const ANNOUNCEMENTS_FETCH_REQUEST = 'ANNOUNCEMENTS_FETCH_REQUEST';
export const ANNOUNCEMENTS_FETCH_SUCCESS = 'ANNOUNCEMENTS_FETCH_SUCCESS';
export const ANNOUNCEMENTS_FETCH_FAIL    = 'ANNOUNCEMENTS_FETCH_FAIL';

export const fetchAnnouncements = () => (dispatch, getState) => {
  dispatch(fetchAnnouncementsRequest());

  api(getState).get('/api/v1/announcements').then(response => {
    dispatch(fetchAnnouncementsSuccess(response.data));
  }).catch(error => {
    dispatch(fetchAnnouncementsFail(error));
  });
};

export const fetchAnnouncementsRequest = () => ({
  type: ANNOUNCEMENTS_FETCH_REQUEST,
  skipLoading: true,
});

export const fetchAnnouncementsSuccess = announcements => ({
  type: ANNOUNCEMENTS_FETCH_SUCCESS,
  announcements,
  skipLoading: true,
});

export const fetchCustomEmojisFail= error => ({
  type: ANNOUNCEMENTS_FETCH_FAIL,
  error,
  skipLoading: true,
});
