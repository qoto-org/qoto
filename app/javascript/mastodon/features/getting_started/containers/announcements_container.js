import { connect } from 'react-redux';
import { fetchAnnouncements } from '../../../actions/announcements';
import Announcements from '../components/announcements';

const mapStateToProps = state => ({
  announcements: state.getIn(['announcements', 'items']),
  domain: state.getIn(['meta', 'domain']),
});

const mapDispatchToProps = dispatch => ({
  fetchAnnouncements: () => dispatch(fetchAnnouncements()),
});

export default connect(mapStateToProps, mapDispatchToProps)(Announcements);
