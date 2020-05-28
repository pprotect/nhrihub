export default {
  delete_callback(data,textStatus,jqxhr){
    return this.parent.remove(this._guid);
  },
  save_complaint() {
    if (this.validate()) {
      const data = this.formData();
      // jQuery correctly sets the contentType and boundary values
      return $.ajax({
        // thanks to http://stackoverflow.com/a/22987941/451893
        //xhr: @progress_bar_create.bind(@)
        method : 'post',
        data,
        url : Routes.complaints_path(current_locale),
        success : this.save_complaint_callback,
        context : this,
        processData : false,
        contentType : false
      });
    }
  },
  formData() {
    // in ractive_local_methods, returns a FormData instance
    return this.asFormData(this.get('persistent_attributes'));
  },
  save_complaint_callback(response, status, jqxhr){
    UserInput.reset();
    this.set(response);
    this.editor.load();
    var complaint_id = this.get('id')
    console.log("persistence save_complaint_callback :: PUSHSTATE")
    console.dir(response)
    history.pushState({page:"save_complaint_callback", content: response},"whatever","/en/complaints/"+complaint_id)
  },
  progress_bar_create() {
    return this.findComponent('progressBar').start();
  },
  update_persist(success, error, context) { // called by InpageEdit
    let fetch = ()=>{
      const data = this.formData();
      $.ajax({
        // thanks to http://stackoverflow.com/a/22987941/451893
        //xhr: @progress_bar_create.bind(@)
        method : 'put',
        data,
        url : this.get('persisted') ? Routes.complaint_path(current_locale, this.get('id')) : undefined,
        success,
        context,
        processData : false,
        contentType : false
      });
    }
    if (this.validate()) {
      this.async_validate().then((remote_validation)=>{
        if(remote_validation){
          fetch();
        }
      })
    }
  }
}

