import api from '../api';

export const HISTORY_FETCH_REQUEST = 'HISTORY_FETCH_REQUEST';
export const HISTORY_FETCH_SUCCESS = 'HISTORY_FETCH_SUCCESS';
export const HISTORY_FETCH_FAIL    = 'HISTORY_FETCH_FAIL';

export const fetchHistory = statusId => (dispatch, getState) => {
  dispatch(fetchHistoryRequest());

  api(getState).get(`/api/v1/statuses/${statusId}/history`)
    .then(({ data }) => dispatch(fetchHistorySuccess(data)))
    .catch(error => dispatch(fetchHistoryFail(error)));
};

export const fetchHistoryRequest = () => ({
  type: HISTORY_FETCH_REQUEST,
});

export const fetchHistorySuccess = history => ({
  type: HISTORY_FETCH_SUCCESS,
  history,
});

export const fetchHistoryFail = error => ({
  type: HISTORY_FETCH_FAIL,
  error,
});
