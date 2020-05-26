const InpageEditDecorator = function(node,id){
  const ractive = this;
  const edit = new InpageEdit({ // see app/assets/javascripts/in_page_edit.coffee
    object : this,
    on : node,
    focus_element : 'input.title',
    success(response, textStatus, jqXhr){
      this.options.object.set(response);
      return this.load();
    },
    error() {
      return console.log("Changes were not saved, for some reason");
    },
  });
  return {
    teardown : id=> {
      return edit.off();
    },
    update : id=> {}
    };
};

Ractive.decorators.inpage_edit = InpageEditDecorator;
