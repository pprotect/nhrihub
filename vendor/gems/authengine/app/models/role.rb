# Roles are hierarchically organized, so that the current role
# for a session can be downgraded to a lower role.
# The hierarchy gives meaning to "lower role".
class Role < ActiveRecord::Base
  attr_accessor :administrator
  has_many :user_roles, :dependent => :destroy
  has_many :users, :through=>:user_roles

  has_many :action_roles, :dependent => :destroy
  has_many :actions, :through => :action_roles

  belongs_to :parent, :class_name => 'Role'

  scope :except_developer, -> { where("name != 'developer'") }
  scope :developer, -> { where(:name => 'developer') }


  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy do
    if users.empty?
      action_roles.clear
    else
      false # don't delete a role if there are users assigned
    end
  end

  after_save RoleAdministrationLogger
  after_destroy RoleAdministrationLogger

  def self.all_with_permitted_action_ids
    all.inject({}){|hash,r| hash[r.id] =r.action_ids; hash}
  end

  # takes either an array of roles or a single role object
  def self.equal_or_lower_than(role)
    roles = role.is_a?(Array) ? role : [role]
    (lower_than(role) + roles).uniq
  end

  # takes either an array of roles or a single role object
  def self.lower_than(role)
    roles = role.is_a?(Array) ? role : [role]
    collection = roles.inject([]) do |ar, r|
      ar + with_ancestor(r)
    end
    (collection).uniq
  end

  # returns an array of roles that have the passed-in role as an
  # ancestor
  def self.with_ancestor(role)
    all.select{|r| r.has_ancestor?(role)}
  end

  def has_ancestor?(role)
    ancestors.include?(role)
  end

  def ancestors
    node, nodes = self, []
    nodes << node = node.parent while node.parent
    nodes
  end

  def is_developer?
    name == 'developer'
  end

  def to_s
    name
  end
end
