export default {
  stash() {
    const stashed_attributes = _(this.get()).pick(this.get('persistent_attributes'));
    Object.assign(stashed_attributes, {attached_documents : this.get('attached_documents')});
    return this.stashed_instance = $.extend(true,{},stashed_attributes);
  },
  restore() {
    return this.set(this.stashed_instance);
  }
};

