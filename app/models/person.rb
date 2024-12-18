class Person < ApplicationRecord
  has_secure_password validations: false
	attr_accessor :password_confirmation

  has_secure_token :random_id
  has_secure_token :verification_token

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  belongs_to :group, required: false

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :about, presence: true
  validates :password, length: { in: 14..72 }, if: Proc.new { |p| p.isgodmother && p.password != nil }
  validates :password, confirmation: true, if: Proc.new { |p| p.isgodmother }
  validates :password_confirmation, presence: true, unless: Proc.new { |p| p.password.blank? }

  ROLES = {
    1 => :mentee,
    2 => :mentor,
    3 => :godmother # This role means, you are a godmother only, but not a mentor
  }.freeze

  STATES = {
    1 => :unverified,
    2 => :verified,
    3 => :okay,
    4 => :waiting,
    5 => :in_group,
    23 => :declined,
    42 => :done
  }.freeze

  def self.state_id(state_name)
    STATES.key(state_name.to_sym)
  end

  def role_name
    ROLES[self.role].to_s
  end

  def role_id
    self.role
  end

  def role_id=(r)
    if r
      self.role = r
      case self.role
      when 1
        self.isgodmother = false
      when 3
        self.isgodmother = true
      end
    end
  end

  def role_name=(r)
    r = ROLES.key(r.to_sym)

    if r      
      self.role = r
      case self.role
      when 1
        self.isgodmother = false
      when 3
        self.isgodmother = true
      end
    else
      self.role = 1
    end
  end

  def self.role_name_to_value(name)
    role = ROLES.key(name.to_sym)
  end

  def role_all
    ROLES.collect { |k, v| k }
  end

  def state_name
    STATES[self.state]
  end

  def state_name=(s)
    s = STATES.key(s.to_sym)

    if s
      self.state = s
    else
      self.state = 1
    end
  end

  def self.state_name_to_value(name)
    STATES.key(name.to_sym)
  end

  def to_param
    random_id
  end

  def self.tagged_with(name)
    Tag.find_by_name!(name).people
  end

  def self.tag_counts
    Tag.select("tags.*, count(taggings.tag_id) as count").
    joins(:taggings).group("taggings.tag_id")
  end

  def tag_list
    tags.map(&:name).join(", ")
  end

  def tag_list=(names)
    self.tags = names.split(",").map do |n|
      Tag.where(name: n.strip.downcase).first_or_create!
    end
  end

  def is_godmother
    self.isgodmother
  end

  def is_godmother=(is_godmother)
    role_to_isgodmother = {
      1 => false,
      2 => is_godmother,
      3 => true
    }
  
    self.isgodmother = role_to_isgodmother[self.role]
  end

  def align_group_state
      if self.state_name == :in_group && self.group_id.blank?
        self.state_name = :waiting
      elsif self.state_name == :done && self.group_id.blank?
        self.state_name = :waiting
      elsif self.state_name != :done && self.state_name != :in_group && self.group_id
        self.state_name = :in_group
      end
  end

  def self.role_options
    [
      ["Mentee", 1],
      ["Mentor", 2],
      ["Godmother Only", 3]
    ]
  end

  def generate_reset_password_token!
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save!
  end

  def clear_reset_password_token!
    self.reset_password_token = nil
    self.reset_password_sent_at = nil
    save!
  end
  
end
