require 'active_support/concern'
module StrategicPlanIndex
  extend ActiveSupport::Concern
  included do
    default_scope ->{ order("#{table_name}.index") }

    after_destroy do
      lower_priority_siblings.each { |pr| pr.decrement_index }
    end

    # strip index if user has entered it
    before_create do
      self.description = self.description.gsub(/^[^a-zA-Z]*/,'')
      self.index = create_index
    end
  end

  def lower_priority_siblings
    # includes self
    siblings.select{|sibling| sibling >= self}
  end

  def siblings
    parent_id = (self.index_parent.class.name.underscore+"_id").to_sym
    siblings = self.class.send(:where, {parent_id => self.send(parent_id)})
  end

  def <=>(other)
    self.index <=> other.index
  end

  def >=(other)
    [0,1].include?(self <=> other)
  end

  def create_index
    increment? ? incremented_index : parent_index+[1]
  end

  def decrement_index
    new_index = index
    new_index[-1] = new_index[-1].pred
    update_attribute(:index, new_index)
    index_descendant.each{|o| o.decrement_index_prefix(new_index)}
  end

  def increment_index_root
    index[0] = index[0].succ
    update_attribute(:index, index)
    index_descendant.each{|a| a.increment_index_root}
  end

  def decrement_index_prefix(new_prefix)
    new_index = new_prefix.dup << self.index[-1]
    update_attribute(:index, new_index)
    index_descendant.each{|o| o.decrement_index_prefix(new_index)}
  end

  def indexed_description
    if description.blank?
      ""
    else
      [index.join('.'), description].join(' ')
    end
  end

  private
  def parent_index
    index_parent.reload.index
  end

  def increment?
    previous_instance && previous_instance.index[0..-2] == parent_index
  end

  def incremented_index
    ar = previous_instance.index
    ar[-1] = ar[-1].succ
    ar
  end

  def previous_instance
    instances = index_parent.send(self.class.name.tableize.to_sym).reload
    instances.last unless instances.blank?
  end
end
