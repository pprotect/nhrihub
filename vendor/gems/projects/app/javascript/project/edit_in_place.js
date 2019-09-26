const EditInPlace = function(node, id) {
  var edit, ractive;
  ractive = this;
  edit = new InpageEdit({
    object: this,
    on: node,
    focus_element: 'input.title',
    //success : (response, statusText, jqxhr)->
    //ractive = @.options.object
    //@.show() # before updating b/c we'll lose the handle
    //ractive.set(response)
    success: function(response, textStatus, jqXhr) {
      this.options.object.set(response);
      return this.load();
    },
    error: function() {
      return console.log("Changes were not saved, for some reason");
    },
    start_callback: function() {
      return ractive.expand();
    }
  });
  return {
    teardown: (id) => {
      return edit.off();
    },
    update: (id) => {}
  };
};

export default EditInPlace
