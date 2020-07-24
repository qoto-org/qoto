import api, { getLinks } from '../api';
import Olm from 'olm';
import olmModule from 'olm/olm.wasm';
import CryptoStore from './crypto/store';

export const CRYPTO_INITIALIZE_REQUEST = 'CRYPTO_INITIALIZE_REQUEST';
export const CRYPTO_INITIALIZE_SUCCESS = 'CRYPTO_INITIALIZE_SUCCESS';
export const CRYPTO_INITIALIZE_FAIL    = 'CRYPTO_INITIALIZE_FAIL ';

const cryptoStore = new CryptoStore();

const loadOlm = () => Olm.init({

  locateFile: path => {
    if (path.endsWith('.wasm')) {
      return olmModule;
    }

    return path;
  },

});

const getRandomBytes = size => {
  const array = new Uint8Array(size);
  crypto.getRandomValues(array);
  return array.buffer;
};

const generateDeviceId = () => {
  const id = new Uint16Array(getRandomBytes(2))[0];
  return id & 0x3fff;
};

export const initializeCryptoRequest = () => ({
  type: CRYPTO_INITIALIZE_REQUEST,
});

export const initializeCryptoSuccess = account => ({
  type: CRYPTO_INITIALIZE_SUCCESS,
  account,
});

export const initializeCryptoFail = error => ({
  type: CRYPTO_INITIALIZE_FAIL,
  error,
});

export const initializeCrypto = () => (dispatch, getState) => {
  dispatch(initializeCryptoRequest());

  loadOlm().then(() => {
    return cryptoStore.getAccount();
  }).then(account => {
    dispatch(initializeCryptoSuccess(account));
  }).catch(err => {
    console.error(err);
    dispatch(initializeCryptoFail(err));
  });
};

export const enableCrypto = () => (dispatch, getState) => {
  dispatch(initializeCryptoRequest());

  loadOlm().then(() => {
    const deviceId = generateDeviceId();
    const account  = new Olm.Account();

    account.create();
    account.generate_one_time_keys(10);

    const deviceName   = 'Browser';
    const identityKeys = JSON.parse(account.identity_keys());
    const oneTimeKeys  = JSON.parse(account.one_time_keys());

    return cryptoStore.storeAccount(account).then(api(getState).post('/api/v1/crypto/keys/upload', {
      device: {
        device_id: deviceId,
        name: deviceName,
        fingerprint_key: identityKeys.ed25519,
        identity_key: identityKeys.curve25519,
      },

      one_time_keys: Object.keys(oneTimeKeys.curve25519).map(key => ({
        key_id: key,
        key: oneTimeKeys.curve25519[key],
        signature: account.sign(oneTimeKeys.curve25519[key]),
      })),
    })).then(() => {
      account.mark_keys_as_published();
    }).then(() => {
      return cryptoStore.storeAccount(account);
    }).then(() => {
      dispatch(initializeCryptoSuccess(account));
    });
  }).catch(err => {
    console.error(err);
    dispatch(initializeCryptoFail(err));
  });
};

const MESSAGE_PREKEY = 0;

export const receiveCrypto = encryptedMessage => (dispatch, getState) => {
  const { account_id, device_id, type, body } = encryptedMessage;
  const deviceKey = `${account_id}:${device_id}`;

  cryptoStore.decryptMessage(deviceKey, type, body).then(payloadString => {
    console.log(encryptedMessage, payloadString);
  });
};
