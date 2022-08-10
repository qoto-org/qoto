import React from 'react';
import { server, domain } from 'mastodon/initial_state';

const ServerBanner = () => (
  <div className='hero-widget'>
    <div className='hero-widget__img'>
      <img src={server.hero} alt={domain} />
    </div>

    <div className='hero-widget__text'>
      <p>{server.description}</p>

      <a href='/about/more' className='button button--block button-secondary'>Learn more</a>
    </div>
  </div>
);

export default ServerBanner;
