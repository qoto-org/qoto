import Dexie from 'dexie';
import Olm from 'olm';

const MESSAGE_TYPE_PREKEY = 0;

export default class CryptoStore {

  constructor() {
    this.pickleKey = 'DEFAULT_KEY';

    this.db = new Dexie('mastodon-crypto');

    this.db.version(1).stores({
      accounts: '',
      sessions: 'deviceKey,sessionId',
    });
  }

  // FIXME: Need to call free() on returned accounts at some point
  // but it needs to happen *after* you're done using them
  getAccount () {
    return this.db.accounts.get('-').then(pickledAccount => {
      if (typeof pickledAccount === 'undefined') {
        return null;
      }

      const account = new Olm.Account();

      account.unpickle(this.pickleKey, pickledAccount);

      return account;
    });
  }

  storeAccount (account) {
    return this.db.accounts.put(account.pickle(this.pickleKey), '-');
  }

  storeSession (deviceKey, session) {
    return this.db.sessions.put({
      deviceKey,
      sessionId: session.session_id(),
      pickledSession: session.pickle(this.pickleKey),
    });
  }

  createInboundSession (deviceKey, type, body) {
    return this.getAccount().then(account => {
      const session = new Olm.Session();

      let payloadString;

      try {
        session.create_inbound(account, body);
        account.remove_one_time_keys(session);
        this.storeAccount(account);

        payloadString = session.decrypt(type, body);

        this.storeSession(deviceKey, session);
      } finally {
        session.free();
        account.free();
      }

      return payloadString;
    });
  }

  // FIXME: Need to call free() on returned sessions at some point
  // but it needs to happen *after* you're done using them
  getSessionsForDevice (deviceKey) {
    return this.db.sessions.where('deviceKey').equals(deviceKey).toArray().then(sessions => sessions.map(sessionData => {
      const session = new Olm.Session();

      session.unpickle(this.pickleKey, sessionData.pickledSession);

      return session;
    }));
  }

  decryptMessage (deviceKey, type, body) {
    return this.getSessionsForDevice(deviceKey).then(sessions => {
      let payloadString;

      sessions.forEach(session => {
        try {
          payloadString = this.decryptMessageForSession(deviceKey, session, type, body);
        } catch (e) {
          console.error(e);
        }
      });

      if (typeof payloadString !== 'undefined') {
        return payloadString;
      }

      if (type === MESSAGE_TYPE_PREKEY) {
        return this.createInboundSession(deviceKey, type, body);
      }
    });
  }

  decryptMessageForSession (deviceKey, session, type, body) {
    const payloadString = session.decrypt(type, body);
    this.storeSession(deviceKey, session);
    return payloadString;
  }

}
