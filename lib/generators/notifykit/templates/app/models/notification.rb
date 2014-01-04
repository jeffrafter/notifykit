class Notification < ActiveRecord::Base
  belongs_to :user

  scope :recent, -> { where('read_at IS NULL AND cancelled_at IS NULL').order('id DESC').limit(3) }

  before_validation :set_email
  before_validation :set_token

  validates :email, presence: true, if: :deliver_via_email?
  validates :email_from, presence: true, if: :deliver_via_email?

  def click
    return false if self.cancelled?
    self.click_count += 1
    self.clicked_at ||= Time.now
    self.save
  end

  def read
    return false if self.cancelled?
    self.read_count += 1
    self.read_at ||= Time.now
    self.save
  end

  def ignore
    return false if self.cancelled?
    self.ignored_at ||= Time.now
    self.save
  end

  def cancel
    return true if self.cancelled_at.present?
    self.update_attribute(:cancelled, Time.now)
  end

  def cancelled?
    self.cancelled_at.present?
  end

  def unsubscribe
    self.unsubscribed_at ||= Time.now
    self.save
  end

  # Note: this is not the email_subject, this is the related resource
  # for the notification, and for some kinds it may be empty.
  def subject
    return @subject if defined?(@subject)
    return if subject_type.blank? || subject_id.blank?
    klass = self.subject_type.constantize
    @object = klass.find(subject_id) rescue nil
  end

  def deliver
    return if self.email_sent_at.present? || !self.deliver_via_email?

    Notifier.notification(self.id).deliver
  end

  protected

  def set_email
    return if !self.deliver_via_email?

    self.email ||= self.user.email rescue nil
  end

  # The default size is 16 which is 1/64^16, this is protected by
  # a unique index in the database to absolutely prevent collisions
  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end

