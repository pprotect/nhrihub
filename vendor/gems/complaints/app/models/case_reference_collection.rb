class CaseReferenceCollection
  attr_accessor :refs

  def initialize(refs=[])
    @refs = refs
  end

  def highest_ref
    @refs.sort.first unless @refs.empty?
  end

  def next_ref
    (highest_ref || CaseReference.new).next_ref
  end

end
