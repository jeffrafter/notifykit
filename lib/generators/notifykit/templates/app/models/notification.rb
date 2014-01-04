class Notification < ActiveRecord::Base

  # List your notification kinds here or pull them from the
  # database (templates).
  NOTIFICATION_KINDS = [
    'welcome'
  ]

  belongs_to :user

  scope :recent, -> { where('read_at IS NULL AND cancelled_at IS NULL').order('id DESC').limit(3) }

  before_validation :set_token

  after_create :send_notification

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

  def email
    res = self.user.email rescue nil
    res
  end

  def subject
    return @subject if defined?(@subject)
    return if subject_type.blank? || subject_id.blank?
    klass = self.subject_type.constantize
    @object = klass.find(subject_id) rescue nil
  end

  protected

  def set_token
  end

  def send_notification
    return if self.email_sent_at.present?

    Notifier.notification(self.id).deliver
  end
end

