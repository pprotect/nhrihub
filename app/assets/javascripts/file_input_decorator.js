const FileInput = function(node) {
  var _reset_input, add_file;
  $(node).on('change', function(event) {
    return add_file(event, this);
  });
  $(node).closest('.fileupload').find('.fileinput-button').on('click', function(event) {
    return $(this).parent().find('input:file').trigger('click');
  });
  add_file = function(event, el) {
    var file, ractive;
    file = el.files[0];
    ractive = Ractive.getContext($(el).closest('.fileupload')[0]).ractive;
    ractive.add_file(file);
    return _reset_input();
  };
  _reset_input = function() {
    var input;
    input = $(node);
    input.wrap('<form></form>').closest('form').get(0).reset();
    return input.unwrap();
  };
  return {
    teardown: function() {
      $(node).off('change');
      return $(node).closest('.fileupload').find('.fileinput-button').off('click');
    },
    update: function() {}
  };
};

export default FileInput

