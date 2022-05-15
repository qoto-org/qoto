import { connect } from 'react-redux';
import LanguageDropdown from '../components/language_dropdown';
import { changeComposeLanguage } from 'mastodon/actions/compose';

const mapStateToProps = state => ({
  value: state.getIn(['compose', 'language']),
});

const mapDispatchToProps = dispatch => ({

  onChange (value) {
    dispatch(changeComposeLanguage(value));
  },

});

export default connect(mapStateToProps, mapDispatchToProps)(LanguageDropdown);
